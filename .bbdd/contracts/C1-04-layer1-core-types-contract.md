# C1-04 - Layer 1 Core Types Contract

## Black Box

Name: Core Domain Type Set

Responsibility: define immutable core type contracts consumed by higher layers.

Layer: Layer 1

## Public Interface

### Issue

- `id :: String.t()`
- `identifier :: String.t()`
- `title :: String.t()`
- `description :: String.t() | nil`
- `priority :: integer() | nil`
- `state :: String.t()`
- `branch_name :: String.t() | nil`
- `url :: String.t() | nil`
- `labels :: [String.t()]`
- `blocked_by :: [blocked_ref()]`
- `created_at :: DateTime.t() | nil`
- `updated_at :: DateTime.t() | nil`

### WorkflowDefinition

- `config :: map()`
- `prompt_template :: String.t()`

### ServiceConfig

- `tracker :: map()`
- `polling :: map()`
- `workspace :: map()`
- `hooks :: map()`
- `agent :: map()`
- `codex :: map()`

### RetryEntry

- `issue_id :: String.t()`
- `identifier :: String.t() | nil`
- `attempt :: pos_integer()`
- `due_at_ms :: non_neg_integer()`
- `error :: String.t() | nil`

### Snapshot

- `running :: [map()]`
- `retrying :: [map()]`
- `codex_totals :: map()`
- `rate_limits :: map() | nil`

## GIVEN / WHEN / THEN Specs

1. GIVEN higher-layer modules
   WHEN they import core contracts
   THEN they depend only on Layer 1 definitions.

2. GIVEN a contract field change request
   WHEN it is required
   THEN it is handled via a new issue and versioned contract update.

3. GIVEN tests for higher layers
   WHEN validating behavior
   THEN they reference public contract fields only.

## Non-Goals

- Defining storage schema details.
- Encoding HTTP/JSON transport-specific field aliases.

## Immutability Notes

- Contract frozen as of 2026-03-04.
- Structural changes require dedicated contract-change issue.
