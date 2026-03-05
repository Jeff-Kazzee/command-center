defmodule Ops.Config do
  @moduledoc """
  Resolves effective service config from workflow front matter and environment inputs.
  """

  alias Ops.ConfigError
  alias Ops.ServiceConfig
  alias Ops.WorkflowDefinition

  @supported_tracker_kinds ~w(linear)
  @tracker_endpoint_default "https://api.linear.app/graphql"
  @tracker_active_states_default ["Todo", "In Progress"]
  @tracker_terminal_states_default ["Closed", "Cancelled", "Canceled", "Duplicate", "Done"]
  @polling_interval_default 30_000
  @workspace_root_default Path.join(System.tmp_dir!(), "symphony_workspaces")
  @hooks_timeout_default 60_000
  @agent_max_concurrent_default 10
  @agent_max_turns_default 20
  @agent_max_retry_backoff_default 300_000
  @codex_command_default "codex app-server"
  @codex_turn_timeout_default 3_600_000
  @codex_read_timeout_default 5_000
  @codex_stall_timeout_default 300_000

  @spec resolve(WorkflowDefinition.t(), map()) ::
          {:ok, ServiceConfig.t()} | {:error, ConfigError.t()}
  def resolve(%WorkflowDefinition{config: config}, env) when is_map(config) and is_map(env) do
    with {:ok, tracker} <- resolve_tracker(config, env),
         {:ok, polling} <- resolve_polling(config),
         {:ok, workspace} <- resolve_workspace(config, env),
         {:ok, hooks} <- resolve_hooks(config),
         {:ok, agent} <- resolve_agent(config),
         {:ok, codex} <- resolve_codex(config) do
      {:ok,
       %ServiceConfig{
         tracker: tracker,
         polling: polling,
         workspace: workspace,
         hooks: hooks,
         agent: agent,
         codex: codex
       }}
    end
  end

  def resolve(%WorkflowDefinition{}, env) when not is_map(env) do
    error(:invalid_config_shape, "environment must be a map", "env")
  end

  def resolve(%WorkflowDefinition{config: config}, _env) when not is_map(config) do
    error(:invalid_config_shape, "workflow config must be a map", "config")
  end

  def resolve(_workflow_def, _env) do
    error(:invalid_config_shape, "workflow definition must be valid", "workflow_def")
  end

  defp resolve_tracker(config, env) do
    with {:ok, tracker} <- section_map(config, "tracker"),
         {:ok, kind} <- resolve_tracker_kind(fetch_value(tracker, "kind")),
         {:ok, api_key} <- resolve_tracker_api_key(tracker, env),
         {:ok, project_slug} <-
           parse_required_string(
             fetch_value(tracker, "project_slug"),
             "tracker.project_slug",
             :missing_tracker_project_slug
           ),
         {:ok, endpoint} <-
           parse_optional_string(
             fetch_value(tracker, "endpoint"),
             "tracker.endpoint",
             @tracker_endpoint_default
           ),
         {:ok, active_states} <-
           parse_string_list(
             fetch_value(tracker, "active_states"),
             "tracker.active_states",
             @tracker_active_states_default
           ),
         {:ok, terminal_states} <-
           parse_string_list(
             fetch_value(tracker, "terminal_states"),
             "tracker.terminal_states",
             @tracker_terminal_states_default
           ) do
      {:ok,
       %{
         kind: kind,
         endpoint: normalize_tracker_endpoint(endpoint),
         api_key: api_key,
         project_slug: project_slug,
         active_states: active_states,
         terminal_states: terminal_states
       }}
    end
  end

  defp resolve_polling(config) do
    with {:ok, polling} <- section_map(config, "polling"),
         {:ok, interval_ms} <-
           parse_integer(
             fetch_value(polling, "interval_ms"),
             "polling.interval_ms",
             @polling_interval_default,
             positive?: true
           ) do
      {:ok, %{interval_ms: interval_ms}}
    end
  end

  defp resolve_workspace(config, env) do
    with {:ok, workspace} <- section_map(config, "workspace"),
         {:ok, root} <- resolve_workspace_root(fetch_value(workspace, "root"), env) do
      {:ok, %{root: root}}
    end
  end

  defp resolve_hooks(config) do
    with {:ok, hooks} <- section_map(config, "hooks"),
         {:ok, after_create} <-
           parse_optional_script(fetch_value(hooks, "after_create"), "hooks.after_create"),
         {:ok, before_run} <-
           parse_optional_script(fetch_value(hooks, "before_run"), "hooks.before_run"),
         {:ok, after_run} <-
           parse_optional_script(fetch_value(hooks, "after_run"), "hooks.after_run"),
         {:ok, before_remove} <-
           parse_optional_script(fetch_value(hooks, "before_remove"), "hooks.before_remove"),
         {:ok, timeout_ms} <- parse_hooks_timeout(fetch_value(hooks, "timeout_ms")) do
      {:ok,
       %{
         after_create: after_create,
         before_run: before_run,
         after_run: after_run,
         before_remove: before_remove,
         timeout_ms: timeout_ms
       }}
    end
  end

  defp resolve_agent(config) do
    with {:ok, agent} <- section_map(config, "agent"),
         {:ok, max_concurrent_agents} <-
           parse_integer(
             fetch_value(agent, "max_concurrent_agents"),
             "agent.max_concurrent_agents",
             @agent_max_concurrent_default,
             positive?: true
           ),
         {:ok, max_turns} <-
           parse_integer(
             fetch_value(agent, "max_turns"),
             "agent.max_turns",
             @agent_max_turns_default,
             positive?: true
           ),
         {:ok, max_retry_backoff_ms} <-
           parse_integer(
             fetch_value(agent, "max_retry_backoff_ms"),
             "agent.max_retry_backoff_ms",
             @agent_max_retry_backoff_default,
             positive?: true
           ),
         {:ok, max_concurrent_agents_by_state} <-
           normalize_state_limit_map(fetch_value(agent, "max_concurrent_agents_by_state")) do
      {:ok,
       %{
         max_concurrent_agents: max_concurrent_agents,
         max_turns: max_turns,
         max_retry_backoff_ms: max_retry_backoff_ms,
         max_concurrent_agents_by_state: max_concurrent_agents_by_state
       }}
    end
  end

  defp resolve_codex(config) do
    with {:ok, codex} <- section_map(config, "codex"),
         {:ok, command} <- resolve_codex_command(fetch_value(codex, "command")),
         {:ok, turn_timeout_ms} <-
           parse_integer(
             fetch_value(codex, "turn_timeout_ms"),
             "codex.turn_timeout_ms",
             @codex_turn_timeout_default,
             positive?: true
           ),
         {:ok, read_timeout_ms} <-
           parse_integer(
             fetch_value(codex, "read_timeout_ms"),
             "codex.read_timeout_ms",
             @codex_read_timeout_default,
             positive?: true
           ),
         {:ok, stall_timeout_ms} <-
           parse_integer(
             fetch_value(codex, "stall_timeout_ms"),
             "codex.stall_timeout_ms",
             @codex_stall_timeout_default,
             positive?: false
           ) do
      {:ok,
       %{
         command: command,
         approval_policy: fetch_value(codex, "approval_policy"),
         thread_sandbox: fetch_value(codex, "thread_sandbox"),
         turn_sandbox_policy: fetch_value(codex, "turn_sandbox_policy"),
         turn_timeout_ms: turn_timeout_ms,
         read_timeout_ms: read_timeout_ms,
         stall_timeout_ms: stall_timeout_ms
       }}
    end
  end

  defp section_map(config, key) do
    case fetch_key(config, key) do
      :error ->
        {:ok, %{}}

      {:ok, nil} ->
        {:ok, %{}}

      {:ok, section} when is_map(section) ->
        {:ok, section}

      {:ok, _section} ->
        error(:invalid_config_shape, "#{key} must be an object", key)
    end
  end

  defp resolve_tracker_api_key(tracker, env) do
    value = fetch_value(tracker, "api_key")

    with {:ok, maybe_api_key} <- parse_optional_string(value, "tracker.api_key", nil),
         api_key <- resolve_env_reference(maybe_api_key, env),
         {:ok, api_key} <- require_present(api_key, :missing_tracker_api_key, "tracker.api_key") do
      {:ok, api_key}
    end
  end

  defp resolve_workspace_root(value, env) do
    with {:ok, root} <- parse_optional_string(value, "workspace.root", nil) do
      root =
        root
        |> resolve_env_reference(env)
        |> case do
          nil -> @workspace_root_default
          "" -> @workspace_root_default
          resolved -> expand_path(resolved)
        end

      {:ok, root}
    end
  end

  defp parse_hooks_timeout(value) do
    with {:ok, timeout_ms} <-
           parse_integer(
             value,
             "hooks.timeout_ms",
             @hooks_timeout_default,
             positive?: false
           ) do
      if timeout_ms <= 0 do
        {:ok, @hooks_timeout_default}
      else
        {:ok, timeout_ms}
      end
    end
  end

  defp resolve_codex_command(nil), do: {:ok, @codex_command_default}

  defp resolve_codex_command(value) when is_binary(value) do
    command = String.trim(value)

    if command == "" do
      error(:missing_codex_command, "codex.command is required", "codex.command")
    else
      {:ok, command}
    end
  end

  defp resolve_codex_command(_value) do
    error(:invalid_config_value, "codex.command must be a string", "codex.command")
  end

  defp validate_tracker_kind(kind) when kind in @supported_tracker_kinds, do: :ok

  defp validate_tracker_kind(kind) do
    error(:invalid_tracker_kind, "tracker.kind is unsupported: #{kind}", "tracker.kind", %{
      value: kind
    })
  end

  defp resolve_tracker_kind(nil) do
    error(:invalid_tracker_kind, "tracker.kind is required and must be supported", "tracker.kind")
  end

  defp resolve_tracker_kind(kind) when is_binary(kind) do
    kind
    |> String.trim()
    |> case do
      "" ->
        error(
          :invalid_tracker_kind,
          "tracker.kind is required and must be supported",
          "tracker.kind"
        )

      value ->
        validate_tracker_kind(value)
    end
    |> case do
      :ok -> {:ok, String.trim(kind)}
      error_result -> error_result
    end
  end

  defp resolve_tracker_kind(kind) do
    error(:invalid_tracker_kind, "tracker.kind must be a supported string", "tracker.kind", %{
      value: kind
    })
  end

  defp normalize_tracker_endpoint(""), do: @tracker_endpoint_default
  defp normalize_tracker_endpoint(endpoint), do: endpoint

  defp normalize_state_limit_map(nil), do: {:ok, %{}}

  defp normalize_state_limit_map(value) when is_map(value) do
    normalized =
      Enum.reduce(value, %{}, fn {key, raw_limit}, acc ->
        normalized_key = normalize_state_key(key)

        case {normalized_key, parse_positive_integer(raw_limit)} do
          {nil, _} -> acc
          {_key, :error} -> acc
          {key, limit} -> Map.put(acc, key, limit)
        end
      end)

    {:ok, normalized}
  end

  defp normalize_state_limit_map(_value) do
    error(
      :invalid_config_value,
      "agent.max_concurrent_agents_by_state must be a map",
      "agent.max_concurrent_agents_by_state"
    )
  end

  defp parse_optional_script(nil, _field), do: {:ok, nil}

  defp parse_optional_script(value, _field) when is_binary(value), do: {:ok, value}

  defp parse_optional_script(_value, field) do
    error(:invalid_config_value, "#{field} must be a string", field)
  end

  defp parse_optional_string(nil, _field, default), do: {:ok, default}

  defp parse_optional_string(value, _field, _default) when is_binary(value) do
    {:ok, String.trim(value)}
  end

  defp parse_optional_string(_value, field, _default) do
    error(:invalid_config_value, "#{field} must be a string", field)
  end

  defp parse_required_string(value, field, code) do
    with {:ok, string_value} <- parse_optional_string(value, field, nil),
         {:ok, required} <- require_present(string_value, code, field) do
      {:ok, required}
    end
  end

  defp require_present(value, code, field) when is_binary(value) do
    trimmed = String.trim(value)

    if trimmed == "" do
      missing_field_error(code, field)
    else
      {:ok, trimmed}
    end
  end

  defp require_present(_value, code, field), do: missing_field_error(code, field)

  defp missing_field_error(:missing_tracker_api_key, field) do
    error(:missing_tracker_api_key, "tracker.api_key is required", field)
  end

  defp missing_field_error(:missing_tracker_project_slug, field) do
    error(:missing_tracker_project_slug, "tracker.project_slug is required", field)
  end

  defp missing_field_error(:invalid_config_value, field) do
    error(:invalid_config_value, "#{field} is required", field)
  end

  defp parse_string_list(nil, _field, default), do: {:ok, default}

  defp parse_string_list(value, _field, _default) when is_binary(value) do
    {:ok, split_csv_string(value)}
  end

  defp parse_string_list(value, field, _default) when is_list(value) do
    value
    |> Enum.reduce_while([], fn entry, acc ->
      case entry do
        entry when is_binary(entry) ->
          trimmed = String.trim(entry)

          if trimmed == "" do
            {:cont, acc}
          else
            {:cont, [trimmed | acc]}
          end

        _ ->
          {:halt, :error}
      end
    end)
    |> case do
      :error -> error(:invalid_config_value, "#{field} must contain only strings", field)
      result -> {:ok, Enum.reverse(result)}
    end
  end

  defp parse_string_list(_value, field, _default) do
    error(:invalid_config_value, "#{field} must be a list or comma-separated string", field)
  end

  defp split_csv_string(value) do
    value
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_integer(nil, _field, default, _opts), do: {:ok, default}

  defp parse_integer(value, field, _default, opts) do
    case coerce_integer(value) do
      {:ok, integer_value} ->
        if opts[:positive?] && integer_value <= 0 do
          error(:invalid_config_value, "#{field} must be a positive integer", field)
        else
          {:ok, integer_value}
        end

      :error ->
        error(:invalid_config_value, "#{field} must be an integer", field, %{value: value})
    end
  end

  defp coerce_integer(value) when is_integer(value), do: {:ok, value}

  defp coerce_integer(value) when is_binary(value) do
    trimmed = String.trim(value)

    if trimmed == "" do
      :error
    else
      case Integer.parse(trimmed) do
        {parsed, ""} -> {:ok, parsed}
        _ -> :error
      end
    end
  end

  defp coerce_integer(_value), do: :error

  defp parse_positive_integer(value) do
    case coerce_integer(value) do
      {:ok, integer_value} when integer_value > 0 -> integer_value
      _ -> :error
    end
  end

  defp normalize_state_key(key) when is_binary(key) do
    key
    |> String.trim()
    |> String.downcase()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_state_key(key) when is_atom(key), do: normalize_state_key(Atom.to_string(key))
  defp normalize_state_key(_key), do: nil

  defp resolve_env_reference(nil, _env), do: nil

  defp resolve_env_reference("$" <> variable, env) do
    variable
    |> lookup_env(env)
    |> case do
      nil -> nil
      value -> String.trim(value)
    end
  end

  defp resolve_env_reference(value, _env), do: value

  defp lookup_env("", _env), do: nil

  defp lookup_env(variable, env) do
    case fetch_key(env, variable) do
      {:ok, nil} ->
        nil

      {:ok, value} ->
        stringify_env_value(value)

      :error ->
        nil
    end
  end

  defp stringify_env_value(value) when is_binary(value), do: value

  defp stringify_env_value(value) do
    case String.Chars.impl_for(value) do
      nil -> nil
      _impl -> to_string(value)
    end
  end

  defp expand_path(path) do
    expanded =
      path
      |> String.trim()
      |> maybe_expand_home()

    if String.contains?(expanded, ["/", "\\"]) do
      Path.expand(expanded)
    else
      expanded
    end
  end

  defp maybe_expand_home("~"), do: System.user_home!()

  defp maybe_expand_home(path) do
    cond do
      String.starts_with?(path, "~/") or String.starts_with?(path, "~\\") ->
        Path.join(System.user_home!(), String.slice(path, 2, String.length(path) - 2))

      true ->
        path
    end
  end

  defp fetch_value(map, key) when is_map(map) do
    case fetch_key(map, key) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  defp fetch_key(map, key) when is_map(map) and is_binary(key) do
    case Map.fetch(map, key) do
      {:ok, value} ->
        {:ok, value}

      :error ->
        Enum.find_value(map, :error, fn
          {candidate_key, value} when is_atom(candidate_key) ->
            if Atom.to_string(candidate_key) == key do
              {:ok, value}
            else
              nil
            end

          _ ->
            nil
        end)
    end
  end

  defp error(code, message, field, details \\ nil) do
    {:error, %ConfigError{code: code, message: message, field: field, details: details}}
  end
end
