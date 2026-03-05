# C1-05 - Workflow Loader Contract

## Black Box

Name: Workflow Loader

Responsibility: load `WORKFLOW.md`, parse optional YAML front matter + Markdown body, and return a typed workflow definition or typed loader error.

Layer: Layer 2 (Data Access)

## Public Interface

### `Ops.Workflow.Loader.load/1`

- Signature: `load(path :: String.t() | nil) :: {:ok, Ops.WorkflowDefinition.t()} | {:error, Ops.WorkflowError.t()}`
- Inputs:
  - `path`: explicit workflow file path when provided; `nil` uses default `./WORKFLOW.md`.
- Output (success):
  - `%Ops.WorkflowDefinition{config: map(), prompt_template: String.t()}`
- Error states (`Ops.WorkflowError.code`):
  - `:missing_workflow_file`
  - `:workflow_parse_error`
  - `:workflow_front_matter_not_a_map`

## GIVEN / WHEN / THEN Specs

1. GIVEN an explicit runtime workflow path
   WHEN `load/1` is called with that path
   THEN the explicit file is loaded even if `./WORKFLOW.md` exists.

2. GIVEN no explicit runtime workflow path
   WHEN `load/1` is called with `nil`
   THEN `./WORKFLOW.md` in the current working directory is loaded.

3. GIVEN a missing or unreadable workflow file
   WHEN `load/1` attempts file read
   THEN it returns `{:error, %Ops.WorkflowError{code: :missing_workflow_file}}`.

4. GIVEN malformed YAML front matter
   WHEN `load/1` parses front matter
   THEN it returns `{:error, %Ops.WorkflowError{code: :workflow_parse_error}}`.

5. GIVEN front matter YAML that decodes to a non-map
   WHEN `load/1` validates decoded front matter
   THEN it returns `{:error, %Ops.WorkflowError{code: :workflow_front_matter_not_a_map}}`.

6. GIVEN a valid workflow file
   WHEN `load/1` succeeds
   THEN it returns config as a map and prompt body as `prompt_template` trimmed string.

## Non-Goals

- Configuration value resolution/coercion/defaulting (C1-06).
- Workflow file watch + dynamic reload behavior (C1-07).
- Prompt template rendering/validation behavior.

## Immutability Notes

- Contract frozen as of: 2026-03-05
- Change requires new issue: yes
