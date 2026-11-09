# Design notes

- Where each rule came from. Read it before arguing with one.
- The history here starts at extraction; the work before it stayed in the source repo.

## Origin

- A private repository used this for five months, 2026-05 to 2026-11.
- 52 commits and 10 closed cards before extraction.
- That version was audited against its own rules, with a grep for every finding.

| Measurement | Result |
| --- | --- |
| Mandatory closing phases completed, across 7 plans | **0 of 7** |
| Readiness drills run against a "required" policy (~11 due) | **1** |
| Archive size, 10 closed cards, before → after | 9,003 → 1,247 lines |

- A rule with a command got followed; a rule with a paragraph did not.
- The same repo added a logging linter and reached 0 violations across 182 files.
- A rule that cannot be a `grep` or a `test -f` was deleted, not tooled.

## What each kept rule earned

| Rule | Evidence it earns its line |
| --- | --- |
| `Verify` as a pasteable command | the only feature that caught real problems |
| Decisions with the rejected option | the code never shows what lost |
| Baseline before the work | no before-number means "down 50%" is unfalsifiable |
| `[v]` separate from `[x]` | five phases carried five sentences of apology, not one word |
| State layer deleted at close | 5,797 of 9,003 archived lines were plans nobody re-read |

## The two blind runs

- Both graded against criteria written before the run, on a repo that never held the workflow.

Run 1: a 114-line change, 8 files, 5.5 minutes.

- Defect: "one sitting" was decided by the party that wanted to start.
- Defect: the opt-out came before any knowledge existed, and left no trace.

Run 2: JWT hardening, 549 lines, 25 files, 19 minutes.

- Full lifecycle, unprompted: `progress.md` first, 10 decisions, the close run by the agent.
- Defect: `## Outcome` had no Command column, so the close destroyed provenance.
- Defect: the baseline was copied from the README, not measured.

## Unproven

- **`## Lessons` has never been populated under test.**
  - Kept on the strength of the source archive, not on evidence.
- **The size boundary is a guess.**
  - Run 1 suggests the opt-out fires for anything one sitting can finish.
- **One author, one model.**
  - Both runs used an agent sharing the author's priors.
  - Failure signals are trustworthy; passes are optimistic.
