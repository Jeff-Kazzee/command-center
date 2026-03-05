# C1 Bootstrap - Plan

## Module Purpose

Establish program scaffolding so all remaining implementation issues can run through a strict BBDD loop.

## Public Contract

- Input: `SPEC.md`, Symphony Elixir reference notes, project scope.
- Output: trackable issue graph + BBDD repo artifacts + naming contract.
- Errors: missing tracker entities, missing artifact folders, inconsistent naming.
- Dependencies: Linear workspace, repository filesystem.

## Layer Placement

- Layer: program-level planning and process artifacts (outside runtime code layers).
- Allowed downward dependencies: docs and templates only.

## Decomposition

1. Seed Linear project, milestones, epics, and issue breakdown.
2. Create `.bbdd` structure and reusable templates.
3. Define immutable Ops naming contract + migration map.
4. Publish cycle operating model + linking SOP.

## Risks

- Risk: no cycle creation API in MCP.
- Mitigation: use dated milestones as cycle equivalent and keep issues ready for direct cycle assignment later.

## Done Criteria

- [x] Contract file written
- [x] Implementation complete
- [x] Tests pass (N/A for docs-only bootstrap)
- [x] Report written

