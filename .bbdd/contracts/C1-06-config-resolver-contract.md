# C1-06 - Config Resolver Contract

## Black Box

Name: Config Resolver

Responsibility: resolve effective service configuration from workflow front matter + environment indirection + built-in defaults, and return typed config errors for invalid required fields or invalid value shapes.

Layer: Layer 3 (Application Logic)

## Public Interface

### `Ops.Config.resolve/2`

- Signature:
  - `resolve(workflow_def :: Ops.WorkflowDefinition.t(), env :: map()) :: {:ok, Ops.ServiceConfig.t()} | {:error, Ops.ConfigError.t()}`
- Inputs:
  - `workflow_def.config`: front matter map from workflow loader.
  - `env`: environment key/value map used for `$VAR` indirection.
- Output (success):
  - `%Ops.ServiceConfig{tracker, polling, workspace, hooks, agent, codex}`
- Error states (`Ops.ConfigError.code`):
  - `:invalid_config_shape`
  - `:invalid_tracker_kind`
  - `:missing_tracker_api_key`
  - `:missing_tracker_project_slug`
  - `:missing_codex_command`
  - `:invalid_config_value`

## GIVEN / WHEN / THEN Specs

1. GIVEN front matter values and resolver defaults
   WHEN `resolve/2` is called
   THEN front matter values take precedence over defaults.

2. GIVEN `$VAR` values for supported fields
   WHEN `resolve/2` is called with `env`
   THEN the resolver dereferences from `env` and applies the resolved value.

3. GIVEN `tracker.api_key: "$VAR"` where `VAR` resolves to empty/missing
   WHEN `resolve/2` is called
   THEN it returns `{:error, %Ops.ConfigError{code: :missing_tracker_api_key}}`.

4. GIVEN `tracker.kind` is missing or unsupported
   WHEN `resolve/2` is called
   THEN it returns `{:error, %Ops.ConfigError{code: :invalid_tracker_kind}}`.

5. GIVEN `tracker.kind == "linear"` and `tracker.project_slug` missing/blank
   WHEN `resolve/2` is called
   THEN it returns `{:error, %Ops.ConfigError{code: :missing_tracker_project_slug}}`.

6. GIVEN `codex.command` missing/blank after normalization
   WHEN `resolve/2` is called
   THEN it returns `{:error, %Ops.ConfigError{code: :missing_codex_command}}`.

7. GIVEN an invalid value shape for typed numeric fields
   WHEN `resolve/2` is called
   THEN it returns `{:error, %Ops.ConfigError{code: :invalid_config_value}}`.

8. GIVEN `agent.max_concurrent_agents_by_state` includes invalid entries
   WHEN `resolve/2` is called
   THEN state keys are normalized (`trim` + `lowercase`) and invalid entries are ignored.

9. GIVEN `workspace.root` path values (`~`, path strings, `$VAR` path)
   WHEN `resolve/2` is called
   THEN path expansion/normalization is applied to path fields only.

10. GIVEN `codex.command` contains shell command syntax
    WHEN `resolve/2` is called
    THEN the command is preserved as a shell command string and not path-expanded.

## Non-Goals

- File watch/reload behavior (C1-07).
- Runtime scheduler preflight orchestration behavior.
- Prompt template rendering behavior.

## Immutability Notes

- Contract frozen as of: 2026-03-05
- Change requires new issue: yes
