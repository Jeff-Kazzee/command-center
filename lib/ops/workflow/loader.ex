defmodule Ops.Workflow.Loader do
  @moduledoc """
  Loads workflow definitions from a Markdown file with optional YAML front matter.
  """

  alias Ops.WorkflowDefinition
  alias Ops.WorkflowError

  @default_workflow_path "./WORKFLOW.md"
  @front_matter_regex ~r/\A---\r?\n(?<front>[\s\S]*?)\r?\n---(?:\r?\n(?<body>[\s\S]*))?\z/

  @spec load(String.t() | nil) :: {:ok, WorkflowDefinition.t()} | {:error, WorkflowError.t()}
  def load(path \\ nil) do
    resolved_path = resolve_path(path)

    case File.read(resolved_path) do
      {:ok, content} ->
        with {:ok, config, body} <- split_and_parse(strip_utf8_bom(content), resolved_path) do
          {:ok,
           %WorkflowDefinition{
             config: config,
             prompt_template: String.trim(body)
           }}
        end

      {:error, reason} ->
        {:error,
         %WorkflowError{
           code: :missing_workflow_file,
           message: "workflow file could not be read",
           path: resolved_path,
           details: reason
         }}
    end
  end

  defp resolve_path(path) when is_binary(path) do
    case String.trim(path) do
      "" -> @default_workflow_path
      trimmed -> trimmed
    end
  end

  defp resolve_path(_), do: @default_workflow_path

  defp strip_utf8_bom(<<239, 187, 191, rest::binary>>), do: rest
  defp strip_utf8_bom(content), do: content

  defp split_and_parse(content, path) do
    case extract_front_matter(content) do
      {:no_front_matter, body} ->
        {:ok, %{}, body}

      {:ok, front_matter, body} ->
        parse_front_matter(front_matter, body, path)

      {:error, reason} ->
        {:error,
         %WorkflowError{
           code: :workflow_parse_error,
           message: "workflow front matter could not be parsed",
           path: path,
           details: reason
         }}
    end
  end

  defp extract_front_matter(content) do
    if String.starts_with?(content, "---") do
      case Regex.named_captures(@front_matter_regex, content) do
        %{"front" => front_matter, "body" => body} ->
          {:ok, front_matter, body || ""}

        nil ->
          {:error, :invalid_front_matter_block}
      end
    else
      {:no_front_matter, content}
    end
  end

  defp parse_front_matter(front_matter, body, path) do
    case YamlElixir.read_from_string(front_matter) do
      {:ok, decoded} ->
        validate_front_matter(decoded, body, path)

      {:error, reason} ->
        {:error,
         %WorkflowError{
           code: :workflow_parse_error,
           message: "workflow front matter could not be parsed",
           path: path,
           details: reason
         }}

      decoded ->
        validate_front_matter(decoded, body, path)
    end
  end

  defp validate_front_matter(decoded, body, _path) when is_map(decoded) do
    {:ok, decoded, body}
  end

  defp validate_front_matter(_decoded, _body, path) do
    {:error,
     %WorkflowError{
       code: :workflow_front_matter_not_a_map,
       message: "workflow front matter must decode to a map",
       path: path,
       details: nil
     }}
  end
end
