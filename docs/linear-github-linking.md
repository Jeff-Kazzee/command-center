# Linear and GitHub Linking SOP

Linear is the status authority. GitHub issues are implementation mirrors.

## Create Flow

1. Create Linear issue first.
2. Set project, epic parent, cycle milestone, estimate.
3. Create GitHub issue in `ops-orchestrator` with title prefix `[<LINEAR-KEY>]`.
4. Add Linear URL in GitHub issue body.
5. Add GitHub issue URL as a link attachment on the Linear issue.

## PR Flow

1. Branch name includes Linear key.
2. PR title includes Linear key.
3. PR description links both Linear and GitHub issue.
4. Status transitions are made in Linear.

## Definition of Ready for In Review

- Contract file exists in `.bbdd/contracts`
- Tests updated for public interface
- Verification report exists in `.bbdd/reports`
- Linear issue includes links to contract/report/PR

