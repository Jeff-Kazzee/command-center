---
tracker:
  kind: linear
  project_slug: "ops-orchestrator"
  api_key: $LINEAR_API_KEY
  active_states:
    - Todo
    - In Progress
  terminal_states:
    - Done
    - Closed
    - Cancelled
    - Canceled
    - Duplicate
polling:
  interval_ms: 30000
workspace:
  root: $OPS_WORKSPACE_ROOT
hooks:
  timeout_ms: 60000
agent:
  max_concurrent_agents: 10
  max_turns: 20
  max_retry_backoff_ms: 300000
codex:
  command: codex app-server
---

You are working on Linear issue {{ issue.identifier }} for Ops Orchestrator.

Title: {{ issue.title }}

Description:
{{ issue.description }}

Execution rules:

1. Follow Black Box Driven Development.
2. Implement only through public interfaces.
3. Preserve layer boundaries.
4. Add/update tests for contract behavior.
5. Produce a verification report artifact.
