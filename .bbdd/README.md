# BBDD Artifacts

This folder stores Black Box Driven Development artifacts for Ops Orchestrator.

## Folders

- `plans/` - feature/module decomposition plans
- `contracts/` - immutable public contracts + GIVEN/WHEN/THEN specs
- `handoffs/` - self-contained prompts for next issue/module handoff
- `reports/` - verification outcomes and audit notes

## Rules

1. One module task per issue.
2. Contract before implementation.
3. Public API is the boundary; no internal leakage in tests.
4. Contract changes require a new issue.

Use `/black box driven development` on every implementation issue.
