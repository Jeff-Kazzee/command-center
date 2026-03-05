# C1-07 - Workflow Watch/Reload Contract

## Black Box

Name: Workflow Watcher

Responsibility: watch workflow source changes, re-load + re-resolve effective config, preserve last known good values on invalid reloads, and expose preflight validation semantics for dispatch loops.

Layer: Layer 3 (Application Logic)

## Public Interface

### `Ops.Workflow.Watcher.start_link/1`

- Signature:
  - `start_link(opts :: keyword()) :: GenServer.on_start()`
- Inputs:
  - `:path` (`String.t() | nil`) workflow path (`nil` uses default `./WORKFLOW.md`).
  - `:poll_interval_ms` (`pos_integer()`) watch check interval (default `1000`).
  - `:env_provider` (`(() -> map())`) resolver env provider (default `&System.get_env/0`).
  - `:loader` (module implementing `load/1`) default `Ops.Workflow.Loader`.
  - `:resolver` (module implementing `resolve/2`) default `Ops.Config`.
- Startup behavior:
  - Performs initial load + resolve before successful start.
  - Returns `{:error, typed_error}` on startup validation failure.

### `Ops.Workflow.Watcher.current/1`

- Signature:
  - `current(server :: GenServer.server()) :: {:ok, Ops.WorkflowDefinition.t(), Ops.ServiceConfig.t()}`
- Behavior:
  - Returns last known good workflow definition + effective config.

### `Ops.Workflow.Watcher.snapshot/1`

- Signature:
  - `snapshot(server :: GenServer.server()) :: map()`
- Returned fields:
  - `workflow_path`
  - `workflow_definition`
  - `service_config`
  - `last_loaded_at_ms`
  - `last_checked_at_ms`
  - `last_reload_error` (nil or typed loader/resolver error)

### `Ops.Workflow.Watcher.refresh/1`

- Signature:
  - `refresh(server :: GenServer.server()) :: :ok | {:error, typed_error}`
- Behavior:
  - Re-reads + re-resolves workflow/config defensively.
  - On failure: keeps last known good effective values and returns typed error.

### `Ops.Workflow.Watcher.validate_dispatch_config/1`

- Signature:
  - `validate_dispatch_config(server :: GenServer.server()) :: :ok | {:error, typed_error}`
- Behavior:
  - Performs defensive refresh and returns validation status used by scheduler preflight.

## GIVEN / WHEN / THEN Specs

1. GIVEN valid startup workflow/config
   WHEN watcher starts
   THEN it starts successfully with loaded effective config.

2. GIVEN startup load/resolve failure
   WHEN watcher starts
   THEN startup fails and returns typed error.

3. GIVEN workflow file changes to a valid config
   WHEN watch refresh executes
   THEN watcher re-applies updated workflow + config without restart.

4. GIVEN workflow file changes to an invalid config
   WHEN watch refresh executes
   THEN watcher keeps last known good workflow/config and stores typed reload error.

5. GIVEN invalid reload state
   WHEN `validate_dispatch_config/1` is called
   THEN it returns `{:error, typed_error}`.

6. GIVEN invalid reload state later fixed in workflow file
   WHEN `validate_dispatch_config/1` is called after fix
   THEN it returns `:ok` and clears prior reload error.

7. GIVEN reload failures
   WHEN they occur
   THEN watcher emits operator-visible logging without crashing.

## Non-Goals

- Poll-and-dispatch orchestration logic.
- In-flight worker restart/replacement on config change.
- Template rendering behavior.

## Immutability Notes

- Contract frozen as of: 2026-03-05
- Change requires new issue: yes
