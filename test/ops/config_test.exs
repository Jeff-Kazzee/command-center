defmodule Ops.ConfigTest do
  use ExUnit.Case, async: true

  alias Ops.Config
  alias Ops.ConfigError
  alias Ops.ServiceConfig
  alias Ops.WorkflowDefinition

  test "resolves defaults for optional sections" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator"
        }
      })

    assert {:ok, %ServiceConfig{} = config} = Config.resolve(workflow, %{})
    assert config.tracker.kind == "linear"
    assert config.tracker.endpoint == "https://api.linear.app/graphql"
    assert config.tracker.active_states == ["Todo", "In Progress"]
    assert config.polling.interval_ms == 30_000
    assert config.workspace.root == Path.join(System.tmp_dir!(), "symphony_workspaces")
    assert config.agent.max_turns == 20
    assert config.codex.command == "codex app-server"
  end

  test "front matter values override defaults with coercion" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator",
          "active_states" => "Todo, In Progress, Blocked",
          "terminal_states" => ["Done", "Closed"]
        },
        "polling" => %{"interval_ms" => "45000"},
        "agent" => %{
          "max_concurrent_agents" => "12",
          "max_turns" => "25",
          "max_retry_backoff_ms" => "600000"
        }
      })

    assert {:ok, %ServiceConfig{} = config} = Config.resolve(workflow, %{})
    assert config.tracker.active_states == ["Todo", "In Progress", "Blocked"]
    assert config.tracker.terminal_states == ["Done", "Closed"]
    assert config.polling.interval_ms == 45_000
    assert config.agent.max_concurrent_agents == 12
    assert config.agent.max_turns == 25
    assert config.agent.max_retry_backoff_ms == 600_000
  end

  test "tracker api key supports $VAR indirection" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "$LINEAR_API_KEY",
          "project_slug" => "ops-orchestrator"
        }
      })

    assert {:ok, %ServiceConfig{} = config} =
             Config.resolve(workflow, %{"LINEAR_API_KEY" => "resolved-key"})

    assert config.tracker.api_key == "resolved-key"
  end

  test "missing resolved tracker api key returns typed error" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "$LINEAR_API_KEY",
          "project_slug" => "ops-orchestrator"
        }
      })

    assert {:error, %ConfigError{} = error} = Config.resolve(workflow, %{})
    assert error.code == :missing_tracker_api_key
    assert error.field == "tracker.api_key"
  end

  test "unsupported tracker kind returns typed error" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "github",
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator"
        }
      })

    assert {:error, %ConfigError{} = error} = Config.resolve(workflow, %{})
    assert error.code == :invalid_tracker_kind
    assert error.field == "tracker.kind"
  end

  test "missing tracker kind returns typed error" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator"
        }
      })

    assert {:error, %ConfigError{} = error} = Config.resolve(workflow, %{})
    assert error.code == :invalid_tracker_kind
    assert error.field == "tracker.kind"
  end

  test "missing project slug for linear returns typed error" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "token-123"
        }
      })

    assert {:error, %ConfigError{} = error} = Config.resolve(workflow, %{})
    assert error.code == :missing_tracker_project_slug
    assert error.field == "tracker.project_slug"
  end

  test "workspace root expands home and env-backed path values" do
    custom_root = Path.join(System.tmp_dir!(), "ops-custom-root")

    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator"
        },
        "workspace" => %{"root" => "$OPS_WORKSPACE_ROOT"}
      })

    assert {:ok, %ServiceConfig{} = config} =
             Config.resolve(workflow, %{"OPS_WORKSPACE_ROOT" => custom_root})

    assert config.workspace.root == Path.expand(custom_root)

    workflow_with_home =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator"
        },
        "workspace" => %{"root" => "~"}
      })

    assert {:ok, %ServiceConfig{} = home_config} = Config.resolve(workflow_with_home, %{})
    assert Path.expand(home_config.workspace.root) == Path.expand(System.user_home!())
  end

  test "codex command is preserved as shell command string" do
    command = "echo $HOME && codex app-server --flag"

    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator"
        },
        "codex" => %{"command" => command}
      })

    assert {:ok, %ServiceConfig{} = config} = Config.resolve(workflow, %{"HOME" => "ignored"})
    assert config.codex.command == command
  end

  test "blank codex command returns typed error" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator"
        },
        "codex" => %{"command" => "   "}
      })

    assert {:error, %ConfigError{} = error} = Config.resolve(workflow, %{})
    assert error.code == :missing_codex_command
    assert error.field == "codex.command"
  end

  test "agent per-state concurrency normalizes keys and ignores invalid entries" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator"
        },
        "agent" => %{
          "max_concurrent_agents_by_state" => %{
            " In Progress " => "3",
            "BLOCKED" => 2,
            "Todo" => 0,
            "Done" => "oops"
          }
        }
      })

    assert {:ok, %ServiceConfig{} = config} = Config.resolve(workflow, %{})

    assert config.agent.max_concurrent_agents_by_state == %{
             "in progress" => 3,
             "blocked" => 2
           }
  end

  test "invalid numeric shape returns typed error" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator"
        },
        "polling" => %{"interval_ms" => "30s"}
      })

    assert {:error, %ConfigError{} = error} = Config.resolve(workflow, %{})
    assert error.code == :invalid_config_value
    assert error.field == "polling.interval_ms"
  end

  test "non-positive hooks timeout falls back to default" do
    workflow =
      workflow_definition(%{
        "tracker" => %{
          "kind" => "linear",
          "api_key" => "token-123",
          "project_slug" => "ops-orchestrator"
        },
        "hooks" => %{"timeout_ms" => 0}
      })

    assert {:ok, %ServiceConfig{} = config} = Config.resolve(workflow, %{})
    assert config.hooks.timeout_ms == 60_000
  end

  defp workflow_definition(config) do
    %WorkflowDefinition{
      config: config,
      prompt_template: "Prompt"
    }
  end
end
