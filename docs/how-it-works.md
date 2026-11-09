# How it works

- The technical half, kept out of the pitch.
- To use it, the [README](../README.md) is enough.

## The board is a directory

```
flow-trail/
  README.md              the board itself: three columns, one card per initiative
  skips.md               changes deliberately not tracked, one row each
  backlog/
    export-csv/          an idea: one page, no plan
      README.md
  doing/
    login-refactor/      the card in flight
      README.md          conclusions, one page — kept
      findings.md        evidence behind them — kept
      progress.md        state, baseline, session log — deleted at close
  done/
    cutoff-tests/        a closed card: README.md, findings.md
```

- One folder per card. The folder it sits in is the column.
- A lane directory appears the first time a card needs it; empty lanes are not created.
- A card moves with `git mv`. Copying it puts the same work in two columns.

## Why the column is a path

- There is no second record of status, so nothing falls out of date.
- `git mv` moves a card, `git log --follow` keeps its history, `git diff` shows the edit.
- Nothing runs: no server, no database, no token, no webhook.
- A branch carries its own board. Merging two branches merges two cards.
- Readable in ten years, with or without this tool or any assistant.

## A card gains and loses a file

| Column | Files | Why that count |
| --- | --- | --- |
| `backlog/` | 1 | an idea needs a page, not a plan |
| `doing/` | 3 | conclusions, evidence, and the state that expires |
| `done/` | 2 | the state is gone; the other two are still true |

- The state file is the only one added on the way in and removed on the way out.
- Starting a card writes `progress.md`; closing it deletes the file.

## Three files, three jobs

| File | Holds | Kind | Dies when |
| --- | --- | --- | --- |
| `README.md` | Six sections of conclusions | what we know | never |
| `findings.md` | Measurements, outputs, excerpts | what we saw | never, capped ~200 |
| `progress.md` | Status, phases, baseline, log | where we are | `git rm` at close |

- The split is by role, not by topic.
- It makes closing mechanical: conclusions up, evidence stays, state deleted.
- Nothing in the state layer is still true tomorrow.

Writing to the wrong file is how a card becomes unreadable:

| What you have | Goes to |
| --- | --- |
| a choice, and what lost | `README ## Decisions` |
| a number, and its command | `Baseline` → `## Outcome` |
| output, excerpt, trace, long table | `findings.md` |
| state, next action, what you tried | `progress.md` |

## The six headings

- Fixed names, fixed order.
- `README.md` is the entry point: conclusion first, the link to `findings.md` second.
- A reader greps the heading; nobody reads the folder top to bottom.

| Section | Answers |
| --- | --- |
| `Outcome` | three sentences, then before / after with the command |
| `Contract` | what still holds, and the command that shows it |
| `Decisions` | the choice, the reason, **what was rejected** |
| `Lessons` | where the next attempt goes differently. `None yet.` is valid |
| `Residual` | what is open, and where it went |
| `Where the proof lives` | the test, the command, the ADR |

## Status markers

- They live in the `progress.md` front matter, and nowhere else.

| Marker | Meaning | Who acts |
| --- | --- | --- |
| `[ ]` | not started | — |
| `[~]` | being written now | agent |
| `[v]` | written, **not** verified | whoever runs the command |
| `[x]` | verified by running it | — |
| `[!]` | blocked, needs a person | named owner |
| `[-]` | dropped, reason on the same line | — |

`[v]` is the commonest real state. `[x]` is never written because the code compiles.

- The column is the coarse status; the phase list is the fine one.
- No file records "the current column" a second time.

## A phase that can fail

- One phase, one layer: schema → service → endpoint → client.
- Each phase leaves the repo runnable, so any session can stop at its boundary.
- Every phase carries a `Verify` command a reader can paste, with its output in the comment.
- A phase that crosses layers cannot be verified or reverted on its own.

## Baseline, then outcome

- Before the first edit, record each metric, its command, and what the command printed.
- A number copied from a document is labelled `quoted from <path>` and does not count.
- At close the pair moves into `README ## Outcome`, command attached.
- That is the only place it survives: `progress.md` is about to be deleted.

## Closing

Three moves, in order:

1. Evidence out of the log — outputs, numbers with context — into `findings.md`, dated.
2. Conclusions out of the log — Outcome with command, decisions with rejections, Residual.
3. Delete and move:

```bash
git rm flow-trail/doing/<card>/progress.md
git mv flow-trail/doing/<card> flow-trail/done/<card>
```

- No summary pass. If closing needed one, the README was not written during the work.
- `findings.md` stays, capped at ~200 lines.
- Past the cap, the bulk becomes a conclusion and the rest is deleted.

## The linter

```bash
bash <this-skill>/scripts/flow-trail-lint.sh flow-trail
```

- Seven error checks: a card in `doing/` has both files; a card in `backlog/` has one.
- And: no `progress.md` in `done/`; six headings; no checkbox; findings linked from its README.
- And: skip rows carry four cells.
- Three warnings: closed README over 120 lines, findings over 200, more than one card in `doing/`.
- It reports, exits 1 on error, gates nothing. No CI job, on purpose.

## The session-start hook

- `scripts/session-start.sh` prints a two-line pointer plus each card's `next:` line.
- It prints nothing in a project without a `flow-trail/` folder.
- Wiring per harness: [hooks](hooks.md).
- Each line carries the date of the card's newest session note.
- Past `FLOW_TRAIL_STALE_DAYS` (default 30) it adds `stale Nd`:

```
doing: flow-trail/doing/parked — waiting on a deploy [last 2026-09-01, stale 66d]
```

- A prompt to look, not a verdict. Deleting a parked card stays a decision.

## Checking that the record is still true

```bash
bash <this-skill>/scripts/verify-outcome.sh          # list what it would run
bash <this-skill>/scripts/verify-outcome.sh --run    # run and compare
```

- Walks every closed card's `## Outcome` table and runs the recorded command.
- `ok` when the recorded After value appears in the output.
- `DRIFT` when it does not. `FAIL` when the command errors. Exit 1 on drift.
- Nothing is modified, and commands only run with `--run`.

## Reading it back

A record nobody reads is a write-only file. Two commands are the read path:

```bash
grep -l -i "<the area>" flow-trail/done/*/README.md 2>/dev/null || true
bash <skill>/scripts/session-start.sh
```

- The first runs before opening a card.
- A closed card that already learned something should be cited, not rediscovered.
- The second runs every session, through the hook.

## Declining a card

- A one-commit change does not need a folder.
- The decision to skip it still gets a row:

```
| Date | Change | Measured before | Why no folder |
| --- | --- | --- | --- |
| 2026-11-07 | rename `auth` middleware | 3 files, 0 tests | one commit |
```

An undocumented skip is how a record stops existing.
Later "too small" and "nobody bothered" look identical.
