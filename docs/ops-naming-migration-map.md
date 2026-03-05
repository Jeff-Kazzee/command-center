# Ops Naming and Migration Map

## Canonical Naming

- Product: `Ops`
- Service: `Ops Orchestrator`
- Runtime namespace: `Ops.*`
- Repository: `ops-orchestrator`

## Legacy to New Term Map

| Legacy | New |
|---|---|
| Symphony | Ops |
| Symphony Service | Ops Orchestrator Service |
| Symphony Elixir | Ops Elixir baseline (reference only) |
| symphony_workspaces | ops_workspaces |
| symphony logs | ops logs |

## Compatibility Guidance

Keep legacy field names only where protocol compatibility requires exact values (for example Codex app-server payload shapes). For docs, CLI output, and internal module naming, use Ops terms only.

## Code-Level Conventions

- Modules use `Ops.` prefix.
- File paths use `ops_` naming.
- Configuration examples prefer `OPS_` env var prefixes.

