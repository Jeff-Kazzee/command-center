defmodule Ops.Workflow.LoaderTest do
  use ExUnit.Case, async: false

  alias Ops.Workflow.Loader
  alias Ops.WorkflowDefinition
  alias Ops.WorkflowError

  test "explicit path is used when provided" do
    with_tmp_dir(fn tmp_dir ->
      default_path = Path.join(tmp_dir, "WORKFLOW.md")
      explicit_path = Path.join(tmp_dir, "custom-workflow.md")

      File.write!(default_path, "---\nsource: default\n---\nDefault prompt")
      File.write!(explicit_path, "---\nsource: explicit\n---\nExplicit prompt")

      File.cd!(tmp_dir, fn ->
        assert {:ok, %WorkflowDefinition{} = definition} = Loader.load(explicit_path)
        assert definition.config["source"] == "explicit"
        assert definition.prompt_template == "Explicit prompt"
      end)
    end)
  end

  test "default path is used when explicit path is absent" do
    with_tmp_dir(fn tmp_dir ->
      workflow_path = Path.join(tmp_dir, "WORKFLOW.md")
      File.write!(workflow_path, "---\nsource: default\n---\nDefault prompt")

      File.cd!(tmp_dir, fn ->
        assert {:ok, %WorkflowDefinition{} = definition} = Loader.load(nil)
        assert definition.config["source"] == "default"
        assert definition.prompt_template == "Default prompt"
      end)
    end)
  end

  test "missing file returns typed error" do
    with_tmp_dir(fn tmp_dir ->
      File.cd!(tmp_dir, fn ->
        assert {:error, %WorkflowError{} = error} = Loader.load(nil)
        assert error.code == :missing_workflow_file
        assert error.path == "./WORKFLOW.md"
      end)
    end)
  end

  test "malformed yaml returns typed error" do
    with_tmp_dir(fn tmp_dir ->
      workflow_path = Path.join(tmp_dir, "WORKFLOW.md")
      File.write!(workflow_path, "---\ntracker: [linear\n---\nPrompt")

      assert {:error, %WorkflowError{} = error} = Loader.load(workflow_path)
      assert error.code == :workflow_parse_error
      assert error.path == workflow_path
    end)
  end

  test "non-map front matter returns typed error" do
    with_tmp_dir(fn tmp_dir ->
      workflow_path = Path.join(tmp_dir, "WORKFLOW.md")
      File.write!(workflow_path, "---\n- linear\n- tracker\n---\nPrompt")

      assert {:error, %WorkflowError{} = error} = Loader.load(workflow_path)
      assert error.code == :workflow_front_matter_not_a_map
      assert error.path == workflow_path
    end)
  end

  test "valid file returns config and prompt_template shape" do
    with_tmp_dir(fn tmp_dir ->
      workflow_path = Path.join(tmp_dir, "WORKFLOW.md")

      File.write!(
        workflow_path,
        """
        ---
        tracker:
          kind: linear
        polling:
          interval_ms: 30000
        ---

          Prompt body for {{ issue.identifier }}.

        """
      )

      assert {:ok, %WorkflowDefinition{} = definition} = Loader.load(workflow_path)
      assert is_map(definition.config)
      assert definition.config["tracker"]["kind"] == "linear"
      assert definition.config["polling"]["interval_ms"] == 30000
      assert definition.prompt_template == "Prompt body for {{ issue.identifier }}."
    end)
  end

  defp with_tmp_dir(fun) do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "ops-workflow-loader-test-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)

    try do
      fun.(tmp_dir)
    after
      File.rm_rf!(tmp_dir)
    end
  end
end
