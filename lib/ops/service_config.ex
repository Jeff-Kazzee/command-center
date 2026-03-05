defmodule Ops.ServiceConfig do
  @moduledoc """
  Public effective service configuration contract.
  """

  @enforce_keys [:tracker, :polling, :workspace, :hooks, :agent, :codex]
  defstruct [:tracker, :polling, :workspace, :hooks, :agent, :codex]

  @type t :: %__MODULE__{
          tracker: map(),
          polling: map(),
          workspace: map(),
          hooks: map(),
          agent: map(),
          codex: map()
        }
end
