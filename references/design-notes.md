# Design notes

- Where every rule came from, and how to delete one.
- Read before changing a rule: each one survived a measurement.

## Origin

- A private repository used this for five months, 2026-05 to 2026-11.
- 52 commits, 10 closed tracks, 4 lanes, 2 templates.
- That version was audited against its own rules, with a grep for every finding.

| Measurement | Result |
| --- | --- |
| Mandatory closing phases completed, across 7 plans | **0 of 7** |
| Readiness drills run against a "required" policy (~11 due) | **1** |
| Share of the 596-line template that is prose about not coding | **43%** |
| Archive size, 10 closed tracks, before → after | 9,003 → 1,247 lines |

- The one track that finished also deleted half its mandatory closing block.
- Not indiscipline: rules a command cannot check were resented by everyone, including their author.
- The same repo added a logging linter, and reached 0 violations across 182 files.
- A rule with a command got followed. A rule with a paragraph did not.

## The board, and why three lanes

The source repo ran five lanes. Extraction kept three, and the merge is the argument:

| Source lane | Here | Why it moved |
| --- | --- | --- |
| intake | `backlog/` | a one-page idea is a state the other columns cannot express |
| plan + active | `doing/` | the phase markers already say whether work has started |
| review + archive | `done/` | closing is three moves; the checklist guarding it ran 0 of 7 |

- A lane here is a directory, so it costs no index, no status field and no lane README.
- That is what separates a column from ceremony: a column can be checked with `ls`.
- A fourth column needs a state the other three cannot hold. None was found; none was added.
- The one card in flight limit is a convention, not a gate: the linter warns, nothing blocks.

## What was kept, and why

| Rule | Evidence it earns its line |
| --- | --- |
| `Verify` as a pasteable command | the only feature that caught real problems |
| Decisions with the rejected option | the code never shows what lost |
| Baseline before the work | no before-number means "down 50%" is unfalsifiable |
| `[v]` separate from `[x]` | five phases carried five sentences of apology, not one word |
| State layer deleted at close | 5,797 of 9,003 archived lines were plans nobody re-read |

## The two blind runs

- Both graded against criteria written before the run.
- Both run on a repository that had never contained the workflow.

Run 1: a 114-line change, 8 files, 5.5 minutes.

- The agent read the protocol, measured a baseline at minute 2, opened no track.
- The number went into its own ephemeral task list, nowhere else.
- Two defects, both in the trigger:
  - The pointer said "read this before anything taking more than one sitting".
  - The party deciding whether it is one sitting is the party that wants to start.
  - The opt-out was available before any knowledge existed, and left no trace.
- Same shape as the old template's "mandatory but trimmable" contradiction.

Run 2: JWT hardening, 549 lines, 25 files, 19 minutes.

- Full lifecycle, unprompted.
- `progress.md` before the first code edit, 10 decisions with rejected options.
- The close (`git rm progress.md`) executed by the agent itself.
- Two defects:
  - `## Outcome` had no Command column, so the close destroyed provenance.
  - The baseline was copied from the repo's README, not measured.
  - It was right only because the docs were a day old.

## How to delete a rule

A rule that cannot fail is decoration. Three questions:

- **Has it ever produced a finding?**
  - The "closed README over 120 lines" check never fired across ten tracks.
  - It survives as a warning, never an error.
- **Can it be a `grep` or a `test -f`?**
  - If not, delete the rule rather than build a tool for it.
- **Does it change a decision, or describe one?**
  - "Consider whether the contract is complete" describes.
  - "Every Contract item names a command that exits 0" decides.

## Unproven

- **`## Lessons` has never been populated under test.**
  - Kept on the strength of the source archive, not on evidence.
- **The size boundary is a guess.**
  - Run 1 suggests the opt-out fires for anything one sitting can finish.
- **One author, one model.**
  - Both runs used an agent sharing the author's priors.
  - Failure signals are trustworthy; passes are optimistic.
