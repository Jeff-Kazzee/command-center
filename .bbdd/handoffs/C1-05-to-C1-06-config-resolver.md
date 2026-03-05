# Next Session Handoff Prompt - C1-06 Config Resolver

Copy/paste the following prompt into a fresh context window:

---

You are continuing work on **Ops Orchestrator** in:

`C:\Users\jeffk\Projects\command-center`

## Current Program State

- Linear project: `Ops Orchestrator`
- Active follow-up issue: `C1-06 Implement config resolver black box`
- Completed this session:
  - Contract: `.bbdd/contracts/C1-05-workflow-loader-contract.md`
  - Loader implementation: `Ops.Workflow.Loader.load/1`
  - Types: `Ops.WorkflowDefinition`, `Ops.WorkflowError`
  - Tests: `test/ops/workflow/loader_test.exs`
  - Report: `.bbdd/reports/C1-05-workflow-loader.md`

## C1-05 Outcome Context

- C1-05 code and tests were added and verified.
- Verification evidence is recorded in `.bbdd/reports/C1-05-workflow-loader.md` with passing test runs.
- Do not change C1-05 public interface unless a dedicated contract-change issue is opened.

## Primary Goal (This Session)

Implement:

`Ops.Config.resolve/2 -> {:ok, ServiceConfig.t()} | {:error, ConfigError.t()}`

Scope is **configuration resolution only** (source precedence, env indirection, coercion/defaults, typed config errors).

Do not implement watcher reload behavior in this issue.

## Required Inputs

1. `SPEC.md` sections:
   - 6.1, 6.3, 6.4
   - 5.3 (front matter schema reference)
   - 17.1 (config parsing/validation matrix)
2. `.bbdd/contracts/C1-04-layer1-core-types-contract.md`
3. `.bbdd/contracts/C1-05-workflow-loader-contract.md`
4. `docs/public-api-contracts.md`

## Required Outputs

1. Contract artifact:
   - `.bbdd/contracts/C1-06-config-resolver-contract.md`
2. Implementation:
   - `Ops.Config.resolve/2`
   - supporting typed config error module(s)
3. Tests:
   - focused tests for resolver behavior only (public interface)
4. Verification report:
   - `.bbdd/reports/C1-06-config-resolver.md`
5. Next handoff:
   - `.bbdd/handoffs/C1-06-to-C1-07-workflow-watcher.md`

## Constraints

- Follow BBDD strictly: `PLAN -> IMPLEMENT -> VERIFY`.
- Respect layer boundaries and immutable public contract surfaces.
- Keep C1-06 scoped to config resolution; no tracker I/O, no orchestrator logic.

## Verification Reminder

If toolchain is available:

```powershell
mix deps.get
mix test
```

If unavailable, document blocker clearly in the C1-06 report and keep issue state aligned with actual verification status.

---
