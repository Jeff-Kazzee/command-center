# Next Session Handoff Prompt - C1-05 Workflow Loader

Copy/paste the following prompt into a fresh context window:

---

You are continuing work on **Ops Orchestrator** in:

`C:\Users\jeffk\Projects\command-center`

## Current Program State

- Linear project: `Ops Orchestrator`
- Active issue: `208-113` (`C1-05 Implement workflow loader black box`) - **In Progress**
- Completed bootstrap issues: `208-109`, `208-110`, `208-111`, `208-112`
- Product naming contract and BBDD scaffolding are already in place.

## Primary Goal (This Session)

Implement the black box:

`Ops.Workflow.Loader.load/1 -> {:ok, WorkflowDefinition.t()} | {:error, WorkflowError.t()}`

Scope is limited to **workflow loading/parsing contract** only (C1-05). Do not implement config resolution (C1-06) or watcher reload (C1-07) in this session.

## Required Inputs

Read these first:

1. `SPEC.md` sections:
   - 5.1, 5.2, 5.3, 5.5
   - 6.1 (path precedence context only)
   - 17.1 (workflow/config parsing test matrix)
2. `.bbdd/contracts/C1-04-layer1-core-types-contract.md`
3. `docs/public-api-contracts.md`
4. `WORKFLOW.md`

## Required Outputs

1. Contract artifact:
   - `.bbdd/contracts/C1-05-workflow-loader-contract.md`
2. Implementation:
   - `Ops.Workflow.Loader.load/1`
   - supporting error type/module(s) for typed failures
3. Tests:
   - focused tests for loader behavior only
4. Verification report:
   - `.bbdd/reports/C1-05-workflow-loader.md`
5. Next handoff:
   - `.bbdd/handoffs/C1-05-to-C1-06-config-resolver.md`

## Behavioral Contract to Enforce

`load/1` must:

1. Resolve workflow path precedence:
   - explicit runtime path wins
   - fallback default is `./WORKFLOW.md`
2. Read file and split YAML front matter + markdown body
3. Return typed errors for:
   - missing workflow file -> `missing_workflow_file`
   - invalid YAML -> `workflow_parse_error`
   - front matter not map -> `workflow_front_matter_not_a_map`
4. Return:
   - `config` as map
   - `prompt_template` as body string (trimmed per spec intent)

## Test Minimums (Public Interface Only)

Add tests for:

1. explicit path is used when provided
2. default path is used when explicit path absent
3. missing file returns typed error
4. malformed YAML returns typed error
5. non-map front matter returns typed error
6. valid file returns `{config, prompt_template}` shape

Do not test private parser internals. Test only through `load/1`.

## Constraints

- Follow BBDD: `PLAN -> IMPLEMENT -> VERIFY`.
- Respect layer boundaries: this module stays in loader scope.
- Keep API surface minimal and immutable.
- Avoid adding unrelated features.

## Definition of Done

- Contract file exists and matches implementation behavior
- Tests for all required scenarios pass
- Verification report is written
- Linear issue `208-113` updated with what changed and report link
- If complete, move `208-113` to `Done`; otherwise keep `In Progress` with clear blocker note

---
