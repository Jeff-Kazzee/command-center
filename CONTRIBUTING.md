# Contributing to Ops Orchestrator

## Workflow

1. Pick a Linear issue in the active cycle.
2. Run `/black box driven development` for that issue.
3. Produce contract, implementation, tests, and verification report.
4. Link PR to Linear + GitHub issue.

## Required Artifacts Per Issue

- `.bbdd/contracts/<issue-key>.md`
- code changes within layer boundaries
- tests via public interfaces
- `.bbdd/reports/<issue-key>.md`

## Branch and PR Naming

- Branch: include Linear key (example: `208-113-workflow-loader`)
- PR title: include Linear key (example: `[208-113] implement workflow loader`)

## Definition of Review Ready

- [ ] Acceptance criteria met
- [ ] Contract unchanged (or separate contract-change issue opened)
- [ ] Tests added/updated
- [ ] Verification report linked in Linear
