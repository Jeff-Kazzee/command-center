# Cutover to Native Linear Cycles

Current state: cycle windows are represented as project milestones because the current MCP tooling does not provide cycle creation.

## Cutover Steps (UI)

1. Open Linear Team Settings -> Workflow and ensure cycles are enabled.
2. Configure 2-week cadence with team timezone set to America/Denver.
3. Create/verify cycles matching:
   - C1: 2026-03-09 to 2026-03-22
   - C2: 2026-03-23 to 2026-04-05
   - C3: 2026-04-06 to 2026-04-19
   - C4: 2026-04-20 to 2026-05-03
4. Bulk assign issues C1-01..C4-07 to the matching native cycle.
5. Keep milestone labels as optional historical grouping or remove if redundant.

## Invariants After Cutover

- WIP limit stays 2.
- Epic and estimate requirements remain unchanged.
- Linear remains status authority.
