# Ops Orchestrator

Ops Orchestrator is an Elixir/OTP service for running coding-agent work against Linear issues using isolated per-issue workspaces and a repository-owned workflow contract.

This repository is currently in planning + bootstrap mode and follows Black Box Driven Development (BBDD).

## Delivery Model

- Product name: `Ops`
- Reference baseline: Symphony Elixir patterns + `SPEC.md`
- Source-of-truth tracker: Linear project `Ops Orchestrator`
- Sprint mechanism: 2-week cycles modeled as C1..C4 milestones
- Issue execution method: `/black box driven development` (`PLAN -> IMPLEMENT -> VERIFY`)

## Repository Structure

- `SPEC.md` - service specification baseline
- `Symphony-Elixer README.md` - reference implementation notes
- `.bbdd/` - BBDD artifacts (plans, contracts, handoffs, reports)
- `docs/` - operating model, naming contracts, design system foundations

## Working Agreement

1. One issue = one black box.
2. Public interface first; internals hidden.
3. Every issue must produce:
   - `.bbdd/contracts/<issue>.md`
   - implementation change
   - tests
   - `.bbdd/reports/<issue>.md`
4. No issue enters `In Review` without contract + tests + report links.

## Current Program

Linear project: [Ops Orchestrator](https://linear.app/the-little-ai-co/project/ops-orchestrator-9b13dea96f17)

See [docs/linear-cycle-operating-model.md](docs/linear-cycle-operating-model.md) for cycle schedule and execution cadence.
