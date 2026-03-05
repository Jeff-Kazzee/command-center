defmodule Ops.ConfigError do
  @moduledoc """
  Typed configuration resolver failure contract.
  """

  @type code ::
          :invalid_config_shape
          | :invalid_tracker_kind
          | :missing_tracker_api_key
          | :missing_tracker_project_slug
          | :missing_codex_command
          | :invalid_config_value

  @enforce_keys [:code, :message]
  defstruct [:code, :message, :field, :details]

  @type t :: %__MODULE__{
          code: code(),
          message: String.t(),
          field: String.t() | nil,
          details: term() | nil
        }
end
