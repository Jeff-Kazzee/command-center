# Next Session Handoff Prompt - C2-01 Linear GraphQL Transport

Copy/paste the following prompt into a fresh context window:

---

You are continuing work on **Ops Orchestrator** in:

`C:\Users\jeffk\Projects\command-center`

## Current Program State

- Linear project: `Ops Orchestrator`
- Completed issue: `208-115` (`C1-07 Implement workflow watch/reload black box`) - implementation complete
- Next issue: `208-116` (`C2-01 Implement Linear GraphQL transport black box`) - currently `Todo`
- Default GitHub branch: `development`
- Branch policy:
  - feature branches: `codex/<issue>-<slug>`
  - merge target: `development`
  - required checks on `development` and `main`: `test`, `CodeRabbit`

## C1-07 Outcome Context (Do Not Rework)

- New workflow watcher contracts + implementation:
  - `.bbdd/contracts/C1-07-workflow-watcher-contract.md`
  - `lib/ops/workflow/watcher.ex`
  - `test/ops/workflow/watcher_test.exs`
  - `.bbdd/reports/C1-07-workflow-watcher.md`
- Existing upstream contracts are frozen:
  - `.bbdd/contracts/C1-05-workflow-loader-contract.md`
  - `.bbdd/contracts/C1-06-config-resolver-contract.md`
  - `.bbdd/contracts/C1-07-workflow-watcher-contract.md`

## Primary Goal (This Session)

Implement the Linear GraphQL transport black box for tracker data access.

Scope:

1. Build a focused transport module for Linear GraphQL requests.
2. Handle HTTP + GraphQL error surfaces in typed form.
3. Support authorization header usage with `tracker.api_key`.
4. Keep API surface minimal for use by later tracker adapter modules.

Do not implement issue normalization or tracker adapter orchestration in this issue.

## Required Inputs

1. `SPEC.md` sections:
   - 11.1 (tracker GraphQL access shape)
   - 11.2 (query/mutation conventions, ID typing)
   - 17.3 (Issue Tracker Client validation matrix)
2. `.bbdd/contracts/C1-04-layer1-core-types-contract.md`
3. `.bbdd/contracts/C1-06-config-resolver-contract.md`
4. `.bbdd/contracts/C1-07-workflow-watcher-contract.md`
5. `docs/public-api-contracts.md`

## Required Outputs

1. Contract artifact:
   - `.bbdd/contracts/C2-01-linear-graphql-transport-contract.md`
2. Implementation:
   - Linear GraphQL transport module(s) with typed error contract
3. Tests:
   - focused transport behavior tests via public interface only
4. Verification report:
   - `.bbdd/reports/C2-01-linear-graphql-transport.md`
5. Next handoff:
   - `.bbdd/handoffs/C2-01-to-C2-02-issue-normalization.md`

## Constraints

- Follow BBDD strictly: `PLAN -> IMPLEMENT -> VERIFY`.
- Respect layer boundaries and frozen contracts.
- Keep C2-01 scoped to transport only.
- Avoid embedding issue normalization logic in transport.

## Verification Reminder

Run and record:

```powershell
mix test
```

Then update Linear `208-116` with:

- implementation summary
- verification report path
- status transition based on verification result

---
