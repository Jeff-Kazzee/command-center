# AGENTS.md

## Purpose
Quick onboarding + working memory for agents in `command-center` (Ops Orchestrator).

## Project Snapshot
- Product: `Ops` (Elixir/OTP orchestration service for Linear-driven coding work)
- Method: Black Box Driven Development (BBDD)
- Tracker: Linear project `Ops Orchestrator`
- Default branch: `development`
- Feature branch format: `codex/<issue>-<slug>`

## Non-Negotiable Rules
1. One issue = one black box.
2. Public API is the contract; do not depend on internals.
3. Follow layers strictly (L1 types -> L2 data access -> L3 logic -> L4 UI).
4. Run `PLAN -> IMPLEMENT -> VERIFY` for every issue.
5. Every issue must produce:
   - contract in `.bbdd/contracts/`
   - implementation + tests
   - verification report in `.bbdd/reports/`
   - next handoff in `.bbdd/handoffs/`

## Current Focus (Next Session)
- Completed: `208-113` / `C1-05 workflow loader` (contract frozen)
- Next: `208-114` / `C1-06 config resolver`
- Target API:
  - `Ops.Config.resolve/2 -> {:ok, ServiceConfig.t()} | {:error, ConfigError.t()}`
- Scope:
  - source precedence (front matter > env indirection > defaults)
  - coercion/normalization
  - typed config errors
- Out of scope:
  - watcher reload behavior (`C1-07`)

## Session Start Checklist
1. Read `NEXT_SESSION_HANDOFF.md`.
2. Read required contract/spec refs listed there.
3. Create/update the issue contract before code.
4. Implement only the scoped black box.
5. Run `mix test` and write the verification report.
