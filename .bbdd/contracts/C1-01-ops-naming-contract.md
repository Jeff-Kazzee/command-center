# C1-01 - Ops Naming Contract

## Black Box

Name: Ops Naming Boundary

Responsibility: define immutable naming rules for all externally visible product/runtime surfaces.

Layer: Layer 1 (Core Types / Constants / Conventions)

## Public Interface

### Contract Constants

- Product name: `Ops`
- Service name: `Ops Orchestrator`
- Root namespace: `Ops.*`
- Repository name target: `ops-orchestrator`

### Mapping Rules

- `Symphony` (old) -> `Ops` (new product identity)
- `Symphony Service` -> `Ops Orchestrator Service`
- `Symphony Elixir` -> `Ops Elixir baseline` (reference label only)
- `symphony_workspaces` default path token -> `ops_workspaces`

## GIVEN / WHEN / THEN Specs

1. GIVEN a new public module
   WHEN naming the module
   THEN it must be under `Ops.*`.

2. GIVEN user-facing docs or logs
   WHEN referencing the product
   THEN they use `Ops` and not `Symphony`.

3. GIVEN migration docs
   WHEN old terms are needed
   THEN include explicit old->new mapping and mark old term as legacy.

## Non-Goals

- Renaming third-party protocol fields that must remain unchanged for compatibility.
- Changing historical issue identifiers in Linear/GitHub.

## Immutability Notes

- Contract frozen as of 2026-03-04.
- Changes require a new naming-contract issue.
