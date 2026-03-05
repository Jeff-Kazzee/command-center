defmodule Ops.WorkflowDefinition do
  @moduledoc """
  Public workflow definition contract loaded from `WORKFLOW.md`.
  """

  @enforce_keys [:config, :prompt_template]
  defstruct [:config, :prompt_template]

  @type t :: %__MODULE__{
          config: map(),
          prompt_template: String.t()
        }
end
