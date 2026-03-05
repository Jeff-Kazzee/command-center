# Next Session Handoff Prompt - C1-07 Workflow Watcher

Copy/paste the following prompt into a fresh context window:

---

You are continuing work on **Ops Orchestrator** in:

`C:\Users\jeffk\Projects\command-center`

## Current Program State

- Linear project: `Ops Orchestrator`
- Completed issue: `208-114` (`C1-06 Implement config resolver black box`) - implementation complete
- Next issue: `C1-07` (`Implement workflow watcher + live reload behavior`)
- Default GitHub branch: `development`
- Branch policy:
  - feature branches: `codex/<issue>-<slug>`
  - merge target: `development`
  - required checks on `development` and `main`: `test`, `CodeRabbit`

## C1-06 Outcome Context (Do Not Rework)

- New config resolver contracts + implementation:
  - `.bbdd/contracts/C1-06-config-resolver-contract.md`
  - `lib/ops/config.ex`
  - `lib/ops/config_error.ex`
  - `lib/ops/service_config.ex`
  - `test/ops/config_test.exs`
- C1-06 report:
  - `.bbdd/reports/C1-06-config-resolver.md`
- C1-06 public contract is frozen unless a new contract-change issue is opened.

## Primary Goal (This Session)

Implement dynamic workflow/config reload behavior (watcher + safe re-apply) per spec.

Scope includes:

1. Watch `WORKFLOW.md` (or configured workflow path) for changes.
2. Re-read workflow and re-resolve config on change.
3. Keep the last known good effective configuration on invalid reload.
4. Emit operator-visible errors on reload failures.
5. Re-validate/reload defensively during runtime operations when watch events may be missed.

Do not broaden scope into unrelated orchestrator features.

## Required Inputs

1. `SPEC.md` sections:
   - 6.2 (Dynamic Reload Semantics)
   - 6.3 (Dispatch Preflight Validation)
   - 16.1 (Service Startup)
   - 17.1 (Workflow and Config Parsing)
2. `.bbdd/contracts/C1-05-workflow-loader-contract.md`
3. `.bbdd/contracts/C1-06-config-resolver-contract.md`
4. `.bbdd/reports/C1-06-config-resolver.md`
5. `docs/public-api-contracts.md`

## Required Outputs

1. Contract artifact:
   - `.bbdd/contracts/C1-07-workflow-watcher-contract.md`
2. Implementation:
   - watcher/reload module(s) and public API surface
3. Tests:
   - focused tests for watch/reload behavior and last-known-good fallback
4. Verification report:
   - `.bbdd/reports/C1-07-workflow-watcher.md`
5. Next handoff:
   - `.bbdd/handoffs/C1-07-to-C1-08-<next-module>.md`

## Constraints

- Follow BBDD strictly: `PLAN -> IMPLEMENT -> VERIFY`.
- Respect frozen contracts from C1-05 and C1-06.
- Invalid reload must not crash service.
- Keep API surface minimal and explicit.

## Verification Reminder

Run and record:

```powershell
mix test
```

Then update the current Linear issue with:

- implementation summary
- verification report path
- status transition based on verification result

---
