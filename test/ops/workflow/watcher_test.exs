defmodule Ops.Workflow.WatcherTest do
  use ExUnit.Case, async: false

  alias Ops.ConfigError
  alias Ops.ServiceConfig
  alias Ops.Workflow.Watcher
  alias Ops.WorkflowDefinition
  alias Ops.WorkflowError

  test "start_link succeeds with valid workflow and exposes current snapshot" do
    with_tmp_dir(fn tmp_dir ->
      workflow_path = Path.join(tmp_dir, "WORKFLOW.md")
      write_workflow!(workflow_path, valid_workflow_content(30_000))

      assert {:ok, pid} =
               Watcher.start_link(
                 path: workflow_path,
                 poll_interval_ms: 10_000,
                 env_provider: fn -> %{} end
               )

      assert {:ok, %WorkflowDefinition{} = workflow, %ServiceConfig{} = config} =
               Watcher.current(pid)

      assert workflow.config["tracker"]["kind"] == "linear"
      assert config.polling.interval_ms == 30_000

      snapshot = Watcher.snapshot(pid)
      assert snapshot.workflow_path == workflow_path
      assert snapshot.last_reload_error == nil
      assert snapshot.last_loaded_at_ms > 0
      assert snapshot.last_checked_at_ms > 0

      GenServer.stop(pid)
    end)
  end

  test "startup fails with typed workflow error when initial load is invalid" do
    with_tmp_dir(fn tmp_dir ->
      workflow_path = Path.join(tmp_dir, "WORKFLOW.md")
      File.write!(workflow_path, "---\ntracker: [linear\n---\nPrompt")

      Process.flag(:trap_exit, true)

      assert {:error, %WorkflowError{} = error} =
               Watcher.start_link(path: workflow_path, poll_interval_ms: 10_000)

      assert error.code == :workflow_parse_error
    end)
  end

  test "refresh applies valid workflow changes without restart" do
    with_tmp_dir(fn tmp_dir ->
      workflow_path = Path.join(tmp_dir, "WORKFLOW.md")
      write_workflow!(workflow_path, valid_workflow_content(30_000))

      assert {:ok, pid} =
               Watcher.start_link(
                 path: workflow_path,
                 poll_interval_ms: 10_000,
                 env_provider: fn -> %{} end
               )

      write_workflow!(workflow_path, valid_workflow_content(45_000))

      assert :ok = Watcher.refresh(pid)
      assert {:ok, _workflow, %ServiceConfig{} = config} = Watcher.current(pid)
      assert config.polling.interval_ms == 45_000

      snapshot = Watcher.snapshot(pid)
      assert snapshot.last_reload_error == nil

      GenServer.stop(pid)
    end)
  end

  test "invalid reload preserves last known good config and records typed error" do
    with_tmp_dir(fn tmp_dir ->
      workflow_path = Path.join(tmp_dir, "WORKFLOW.md")
      write_workflow!(workflow_path, valid_workflow_content(30_000))

      assert {:ok, pid} =
               Watcher.start_link(
                 path: workflow_path,
                 poll_interval_ms: 10_000,
                 env_provider: fn -> %{} end
               )

      File.write!(workflow_path, "---\ntracker: [linear\n---\nPrompt")

      assert {:error, %WorkflowError{} = reload_error} = Watcher.refresh(pid)
      assert reload_error.code == :workflow_parse_error

      assert {:ok, _workflow, %ServiceConfig{} = config} = Watcher.current(pid)
      assert config.polling.interval_ms == 30_000

      snapshot = Watcher.snapshot(pid)
      assert %WorkflowError{} = snapshot.last_reload_error

      GenServer.stop(pid)
    end)
  end

  test "validate_dispatch_config returns error on invalid reload and recovers after fix" do
    with_tmp_dir(fn tmp_dir ->
      workflow_path = Path.join(tmp_dir, "WORKFLOW.md")
      write_workflow!(workflow_path, valid_workflow_content(30_000))

      assert {:ok, pid} =
               Watcher.start_link(
                 path: workflow_path,
                 poll_interval_ms: 10_000,
                 env_provider: fn -> %{} end
               )

      File.write!(
        workflow_path,
        """
        ---
        tracker:
          kind: linear
          api_key: "$LINEAR_API_KEY"
          project_slug: ops-orchestrator
        ---
        Prompt
        """
      )

      assert {:error, %ConfigError{} = error} = Watcher.validate_dispatch_config(pid)
      assert error.code == :missing_tracker_api_key

      write_workflow!(workflow_path, valid_workflow_content(60_000))

      assert :ok = Watcher.validate_dispatch_config(pid)
      snapshot = Watcher.snapshot(pid)
      assert snapshot.last_reload_error == nil

      assert {:ok, _workflow, %ServiceConfig{} = config} = Watcher.current(pid)
      assert config.polling.interval_ms == 60_000

      GenServer.stop(pid)
    end)
  end

  test "watch tick detects workflow change and applies reload automatically" do
    with_tmp_dir(fn tmp_dir ->
      workflow_path = Path.join(tmp_dir, "WORKFLOW.md")
      write_workflow!(workflow_path, valid_workflow_content(30_000))

      assert {:ok, pid} =
               Watcher.start_link(
                 path: workflow_path,
                 poll_interval_ms: 25,
                 env_provider: fn -> %{} end
               )

      write_workflow!(workflow_path, valid_workflow_content(750_000))

      assert wait_until(fn ->
               case Watcher.current(pid) do
                 {:ok, _workflow, %ServiceConfig{} = config} ->
                   config.polling.interval_ms == 750_000

                 _ ->
                   false
               end
             end)

      GenServer.stop(pid)
    end)
  end

  defp valid_workflow_content(interval_ms) do
    """
    ---
    tracker:
      kind: linear
      api_key: token-123
      project_slug: ops-orchestrator
    polling:
      interval_ms: #{interval_ms}
    codex:
      command: codex app-server
    ---
    Prompt body.
    """
  end

  defp write_workflow!(path, content) do
    File.write!(path, content)
    # Ensure a distinct mtime bucket on fast filesystems for watcher fingerprint checks.
    Process.sleep(5)
  end

  defp wait_until(fun, timeout_ms \\ 1_000) do
    started_at = System.monotonic_time(:millisecond)
    do_wait_until(fun, started_at, timeout_ms)
  end

  defp do_wait_until(fun, started_at, timeout_ms) do
    if fun.() do
      true
    else
      if System.monotonic_time(:millisecond) - started_at >= timeout_ms do
        false
      else
        Process.sleep(20)
        do_wait_until(fun, started_at, timeout_ms)
      end
    end
  end

  defp with_tmp_dir(fun) do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "ops-workflow-watcher-test-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)

    try do
      fun.(tmp_dir)
    after
      File.rm_rf!(tmp_dir)
    end
  end
end
