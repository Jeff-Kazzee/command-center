defmodule Ops.WorkflowError do
  @moduledoc """
  Typed workflow loader failure contract.
  """

  @type code ::
          :missing_workflow_file
          | :workflow_parse_error
          | :workflow_front_matter_not_a_map

  @enforce_keys [:code, :message]
  defstruct [:code, :message, :path, :details]

  @type t :: %__MODULE__{
          code: code(),
          message: String.t(),
          path: String.t() | nil,
          details: term() | nil
        }
end
