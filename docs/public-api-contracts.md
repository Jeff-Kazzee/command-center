# Public API Contracts (Frozen Boundaries)

These interfaces are the initial public contracts for Ops Orchestrator.

## Workflow

- `Ops.Workflow.Loader.load(path) -> {:ok, WorkflowDefinition.t()} | {:error, WorkflowError.t()}`

## Config

- `Ops.Config.resolve(workflow_def, env) -> {:ok, ServiceConfig.t()} | {:error, ConfigError.t()}`

## Tracker Adapter

Behavior callbacks:

1. `fetch_candidate_issues(config)`
2. `fetch_issues_by_states(config, state_names)`
3. `fetch_issue_states_by_ids(config, issue_ids)`

## Workspace

- `Ops.Workspace.Manager.prepare(issue_identifier, config) -> {:ok, Workspace.t()} | {:error, WorkspaceError.t()}`

## Agent Client

- `Ops.Agent.Client.start_session(args)`
- `Ops.Agent.Client.run_turn(session, prompt, meta)`
- `Ops.Agent.Client.stop_session(session)`

## Orchestrator

- `Ops.Orchestrator.start_link(opts)`
- `Ops.Orchestrator.snapshot(pid)`
- `Ops.Orchestrator.refresh(pid)`

## Optional HTTP Extension

1. `GET /api/v1/state`
2. `GET /api/v1/:issue_identifier`
3. `POST /api/v1/refresh`
