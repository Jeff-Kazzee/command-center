# Linear Cycle Operating Model

## Project

- Team: `Celebrate Salmon`
- Project: `Ops Orchestrator`
- URL: https://linear.app/the-little-ai-co/project/ops-orchestrator-9b13dea96f17

## Cycle Windows

The current implementation uses project milestones with fixed sprint dates:

| Cycle | Date Range (America/Denver) | Milestone |
|---|---|---|
| C1 | 2026-03-09 to 2026-03-22 | `C1 (2026-03-09 to 2026-03-22)` |
| C2 | 2026-03-23 to 2026-04-05 | `C2 (2026-03-23 to 2026-04-05)` |
| C3 | 2026-04-06 to 2026-04-19 | `C3 (2026-04-06 to 2026-04-19)` |
| C4 | 2026-04-20 to 2026-05-03 | `C4 (2026-04-20 to 2026-05-03)` |

## Status Workflow

- Active statuses: `Todo`, `In Progress`, `In Review`
- Completion/cancel statuses: `Done`, `Canceled`, `Duplicate`
- Optional statuses (`Rework`, `Human Review`, `Merging`) only if workflow policy needs them.

## WIP and Hygiene

- WIP limit per assignee: `2` issues in `In Progress`.
- Every active issue must have:
  - parent epic
  - estimate
  - cycle milestone
- No issue enters `In Review` without contract/test/report artifacts.

## Daily Habit

- Start-of-day (15 min):
  - review current cycle board
  - enforce WIP <= 2
  - select one active issue
  - run `/black box driven development`
- End-of-day (5 min):
  - comment `Done / Next / Blocked` on active issue(s)

## Weekly Habit

- Monday: scope and estimates
- Friday: conformance gate review against Section 17 target for active cycle

