# Next Session Handoff Prompt - C1-06 Config Resolver

Copy/paste the following prompt into a fresh context window:

---

You are continuing work on **Ops Orchestrator** in:

`C:\Users\jeffk\Projects\command-center`

## Current Program State

- Linear project: `Ops Orchestrator`
- Completed issue: `208-113` (`C1-05 Implement workflow loader black box`) - **Done**
- Next issue: `208-114` (`C1-06 Implement config resolver black box`) - currently **Todo**
- Default GitHub branch: `development`
- Branch policy:
  - feature branches: `codex/<issue>-<slug>`
  - merge target: `development`
  - required checks on `development` and `main`: `test`, `CodeRabbit`
  - required approvals: `development=0`, `main=1`

## Primary Goal (This Session)

Implement the black box:

`Ops.Config.resolve/2 -> {:ok, ServiceConfig.t()} | {:error, ConfigError.t()}`

Scope is **configuration resolution only** (C1-06): source precedence, coercion/defaulting, env indirection, and typed config errors.

Do not implement watcher reload behavior (C1-07) in this session.

## Required Inputs

1. `SPEC.md` sections:
   - 6.1, 6.3, 6.4
   - 5.3 (front matter schema reference)
   - 17.1 (workflow/config parsing matrix)
2. `.bbdd/contracts/C1-04-layer1-core-types-contract.md`
3. `.bbdd/contracts/C1-05-workflow-loader-contract.md`
4. `.bbdd/reports/C1-05-workflow-loader.md`
5. `docs/public-api-contracts.md`
6. `WORKFLOW.md`

## Current C1-05 Implementation Context (Do Not Rework)

- Loader black box exists and is verified:
  - `lib/ops/workflow/loader.ex`
  - `lib/ops/workflow_definition.ex`
  - `lib/ops/workflow_error.ex`
  - `test/ops/workflow/loader_test.exs` (8 passing tests)
- C1-05 includes hardening for:
  - UTF-8 BOM-prefixed `WORKFLOW.md`
  - explicit path whitespace trimming
- C1-05 contract is frozen unless a new contract-change issue is opened.

## Required Outputs

1. Contract artifact:
   - `.bbdd/contracts/C1-06-config-resolver-contract.md`
2. Implementation:
   - `Ops.Config.resolve/2`
   - supporting typed config error module(s)
3. Tests:
   - focused tests for resolver behavior via public interface only
4. Verification report:
   - `.bbdd/reports/C1-06-config-resolver.md`
5. Next handoff:
   - `.bbdd/handoffs/C1-06-to-C1-07-workflow-watcher.md`

## C1-06 Behavioral Contract Focus

1. Source precedence:
   - workflow front matter values
   - `$VAR` indirection resolution
   - built-in defaults
2. Coercions and normalization per spec:
   - integer/string-integer fields
   - path expansion (`~`, env-backed paths where applicable)
   - preserve shell command semantics for `codex.command`
3. Typed config errors for invalid required fields / invalid value shapes.
4. Output shape must satisfy `ServiceConfig` contract.

## Constraints

- Follow BBDD: `PLAN -> IMPLEMENT -> VERIFY`.
- Respect layer boundaries: stay in config resolver scope.
- Keep API surface minimal and immutable.
- Avoid adding unrelated features.
- Open a feature branch from `development`; merge back via PR.

## Definition of Done

- Contract file exists and matches implementation behavior.
- Resolver tests pass locally and in CI (`test` + `CodeRabbit` checks green on PR).
- Verification report is written and linked in Linear.
- Linear issue `208-114` updated with implementation summary + report path.
- Move `208-114` to `Done` only after verification and merge complete.

---
