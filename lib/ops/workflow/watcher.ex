defmodule Ops.Workflow.Watcher do
  @moduledoc """
  Watches workflow file changes and maintains last known good effective config.
  """

  use GenServer

  require Logger

  alias Ops.ServiceConfig
  alias Ops.WorkflowDefinition

  @default_workflow_path "./WORKFLOW.md"
  @default_poll_interval_ms 1_000

  defmodule State do
    @enforce_keys [
      :workflow_path,
      :poll_interval_ms,
      :loader,
      :resolver,
      :env_provider,
      :current_fingerprint,
      :last_good_workflow_definition,
      :last_good_service_config,
      :last_loaded_at_ms,
      :last_checked_at_ms
    ]
    defstruct [
      :workflow_path,
      :poll_interval_ms,
      :loader,
      :resolver,
      :env_provider,
      :current_fingerprint,
      :last_good_workflow_definition,
      :last_good_service_config,
      :last_loaded_at_ms,
      :last_checked_at_ms,
      :last_reload_error,
      :last_reload_error_fingerprint
    ]

    @type t :: %__MODULE__{
            workflow_path: String.t(),
            poll_interval_ms: pos_integer(),
            loader: module(),
            resolver: module(),
            env_provider: (() -> map()),
            current_fingerprint: term(),
            last_good_workflow_definition: WorkflowDefinition.t(),
            last_good_service_config: ServiceConfig.t(),
            last_loaded_at_ms: non_neg_integer(),
            last_checked_at_ms: non_neg_integer(),
            last_reload_error: term() | nil,
            last_reload_error_fingerprint: term() | nil
          }
  end

  @type option ::
          {:path, String.t() | nil}
          | {:poll_interval_ms, pos_integer()}
          | {:loader, module()}
          | {:resolver, module()}
          | {:env_provider, (() -> map())}
          | {:name, GenServer.name()}

  @type snapshot :: %{
          workflow_path: String.t(),
          workflow_definition: WorkflowDefinition.t(),
          service_config: ServiceConfig.t(),
          last_loaded_at_ms: non_neg_integer(),
          last_checked_at_ms: non_neg_integer(),
          last_reload_error: term() | nil
        }

  @spec start_link([option()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    case Keyword.fetch(opts, :name) do
      {:ok, name} -> GenServer.start_link(__MODULE__, opts, name: name)
      :error -> GenServer.start_link(__MODULE__, opts)
    end
  end

  @spec current(GenServer.server()) :: {:ok, WorkflowDefinition.t(), ServiceConfig.t()}
  def current(server), do: GenServer.call(server, :current)

  @spec snapshot(GenServer.server()) :: snapshot()
  def snapshot(server), do: GenServer.call(server, :snapshot)

  @spec refresh(GenServer.server()) :: :ok | {:error, term()}
  def refresh(server), do: GenServer.call(server, :refresh)

  @spec validate_dispatch_config(GenServer.server()) :: :ok | {:error, term()}
  def validate_dispatch_config(server), do: GenServer.call(server, :validate_dispatch_config)

  @impl true
  def init(opts) do
    workflow_path = resolve_path(Keyword.get(opts, :path))
    poll_interval_ms = normalize_poll_interval(Keyword.get(opts, :poll_interval_ms, @default_poll_interval_ms))
    loader = Keyword.get(opts, :loader, Ops.Workflow.Loader)
    resolver = Keyword.get(opts, :resolver, Ops.Config)
    env_provider = Keyword.get(opts, :env_provider, &System.get_env/0)
    fingerprint = workflow_fingerprint(workflow_path)
    now_ms = now_ms()

    case load_and_resolve(workflow_path, loader, resolver, env_provider) do
      {:ok, workflow_definition, service_config} ->
        state = %State{
          workflow_path: workflow_path,
          poll_interval_ms: poll_interval_ms,
          loader: loader,
          resolver: resolver,
          env_provider: env_provider,
          current_fingerprint: fingerprint,
          last_good_workflow_definition: workflow_definition,
          last_good_service_config: service_config,
          last_loaded_at_ms: now_ms,
          last_checked_at_ms: now_ms,
          last_reload_error: nil,
          last_reload_error_fingerprint: nil
        }

        schedule_watch_tick(poll_interval_ms)
        {:ok, state}

      {:error, error} ->
        {:stop, error}
    end
  end

  @impl true
  def handle_call(:current, _from, state) do
    {:reply, {:ok, state.last_good_workflow_definition, state.last_good_service_config}, state}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, snapshot_from_state(state), state}
  end

  @impl true
  def handle_call(:refresh, _from, state) do
    {:ok, next_state} = refresh_state(state, :manual, true)
    {:reply, validation_result(next_state), next_state}
  end

  @impl true
  def handle_call(:validate_dispatch_config, _from, state) do
    {:ok, next_state} = refresh_state(state, :preflight, true)
    {:reply, validation_result(next_state), next_state}
  end

  @impl true
  def handle_info(:watch_tick, state) do
    {:ok, next_state} = refresh_state(state, :watch, false)
    schedule_watch_tick(next_state.poll_interval_ms)
    {:noreply, next_state}
  end

  defp refresh_state(state, source, force_reload?) do
    fingerprint = workflow_fingerprint(state.workflow_path)
    now_ms = now_ms()
    should_reload = force_reload? or fingerprint != state.current_fingerprint

    if should_reload do
      case load_and_resolve(state.workflow_path, state.loader, state.resolver, state.env_provider) do
        {:ok, workflow_definition, service_config} ->
          maybe_log_reload_success(state, source, fingerprint)

          {:ok,
           %State{
             state
             | current_fingerprint: fingerprint,
               last_good_workflow_definition: workflow_definition,
               last_good_service_config: service_config,
               last_loaded_at_ms: now_ms,
               last_checked_at_ms: now_ms,
               last_reload_error: nil,
               last_reload_error_fingerprint: nil
           }}

        {:error, error} ->
          maybe_log_reload_error(state, source, fingerprint, error)

          {:ok,
           %State{
             state
             | current_fingerprint: fingerprint,
               last_checked_at_ms: now_ms,
               last_reload_error: error,
               last_reload_error_fingerprint: fingerprint
           }}
      end
    else
      {:ok, %State{state | last_checked_at_ms: now_ms}}
    end
  end

  defp load_and_resolve(workflow_path, loader, resolver, env_provider) do
    with {:ok, workflow_definition} <- loader.load(workflow_path),
         {:ok, service_config} <- resolver.resolve(workflow_definition, read_env(env_provider)) do
      {:ok, workflow_definition, service_config}
    end
  end

  defp validation_result(%State{last_reload_error: nil}), do: :ok
  defp validation_result(%State{last_reload_error: error}), do: {:error, error}

  defp snapshot_from_state(state) do
    %{
      workflow_path: state.workflow_path,
      workflow_definition: state.last_good_workflow_definition,
      service_config: state.last_good_service_config,
      last_loaded_at_ms: state.last_loaded_at_ms,
      last_checked_at_ms: state.last_checked_at_ms,
      last_reload_error: state.last_reload_error
    }
  end

  defp maybe_log_reload_success(state, :startup, _fingerprint), do: state

  defp maybe_log_reload_success(state, source, fingerprint) do
    if state.last_reload_error != nil or fingerprint != state.current_fingerprint do
      Logger.info("workflow reload succeeded (source=#{source}, path=#{state.workflow_path})")
    end
  end

  defp maybe_log_reload_error(state, _source, fingerprint, error) do
    if should_log_reload_error?(state, fingerprint, error) do
      Logger.error(
        "workflow reload failed (path=#{state.workflow_path}): #{inspect(error, pretty: true, limit: :infinity)}"
      )
    end
  end

  defp should_log_reload_error?(state, fingerprint, error) do
    state.last_reload_error == nil or
      state.last_reload_error_fingerprint != fingerprint or
      state.last_reload_error != error
  end

  defp resolve_path(path) when is_binary(path) do
    case String.trim(path) do
      "" -> @default_workflow_path
      trimmed -> trimmed
    end
  end

  defp resolve_path(_), do: @default_workflow_path

  defp normalize_poll_interval(value) when is_integer(value) and value > 0, do: value
  defp normalize_poll_interval(_), do: @default_poll_interval_ms

  defp schedule_watch_tick(poll_interval_ms) do
    Process.send_after(self(), :watch_tick, poll_interval_ms)
  end

  defp read_env(env_provider) do
    case env_provider.() do
      env when is_map(env) -> env
      _ -> %{}
    end
  rescue
    _ -> %{}
  end

  defp workflow_fingerprint(path) do
    case File.stat(path) do
      {:ok, %File.Stat{mtime: mtime, size: size}} ->
        {:ok, {mtime, size}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp now_ms, do: System.system_time(:millisecond)
end
