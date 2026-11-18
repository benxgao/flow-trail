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

## The backlog, kept current

- An idea gets a page the day it arrives, with the trigger that would start it.
- The backlog is read at two moments: when a plan opens, and when a card closes.
- Between them it is edited, never rewritten. The page keeps the idea as it arrived.

| Event | What happens to the page |
| --- | --- |
| a plan opens in the same area | it is started, or it gets one line saying why it stays parked |
| a card closes with leftover work | one `Residual` line is added to the page that leftover names |
| a trigger fires | `git mv` into `doing/`; the page becomes the card's README |
| the idea stops mattering | the folder is deleted; the commit is the record |

- Twelve weeks of that is a roadmap nobody had to schedule.
- Nothing summarises the backlog into one plan: the summary is the copy that goes stale.
- The reading is `grep -l -i "<the area>" flow-trail/backlog/*/README.md`, once per plan.

## Three files, three jobs

| File | Holds | Kind | Dies when |
| --- | --- | --- | --- |
| `README.md` | Six sections of conclusions | what we know | never |
| `findings.md` | Numbered findings, then receipts | what we saw, and what it cost not to know | never, capped ~200 |
| `progress.md` | Status, phases, baseline, log | where we are | `git rm` at close |

- The split is by role, not by topic.
- It makes closing mechanical: conclusions up, evidence stays, state deleted.
- Nothing in the state layer is still true tomorrow.
- `usage.md` is not a card file: it lives beside the columns, because the event it records happens
  after the card closed. One row per later task that actually used a finding.

Writing to the wrong file is how a card becomes unreadable:

| What you have | Goes to |
| --- | --- |
| a choice, and what lost | `README ## Decisions` |
| a number, and its command | `Baseline` → `## Outcome` |
| a finding, what it costs, what cites it | `findings.md ## F<n>` |
| a number that only proves work happened | `findings.md ## Receipts` |
| a later task that used a finding | `usage.md` |
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

1. Evidence out of the log — each finding becomes an `F` entry with what it implies, what it costs
   to not know, and what cites it. Numbers that only proved work happened go under `## Receipts`,
   dated, where they can be deleted without losing anything.
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

- Thirteen error checks: a card in `doing/` has both files; a card in `backlog/` has one.
- And: no `progress.md` in `done/`; six headings; no checkbox; findings linked from its README.
- And: skip rows carry four cells.
- And: findings headings are `## F<n> —`, `## Reference` or `## Receipts`; a `## Measurements`
  section is a receipt wearing a finding's name.
- And: each `F` entry carries `Cost if unknown` and `Cited by`, counted per file.
- And: each `F` entry carries `Not in the code because`, and exactly one of `Check` / `Dies when`.
- And: every citation resolves. `path :: needle` — the file exists and the string is still in it.
  A `path:line` citation warns instead, because no check can tell a moved line from a dead one.
- And: a closed README never points at `progress.md`, which is deleted at close.
- Six warnings: closed README over 120 lines, findings over 200, more than one card in `doing/`,
  a card with no `usage.md` beside it, a closed card unused past `FLOW_TRAIL_SILENT_DAYS`, and a
  `path:line` citation.
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
- One more line names the three most recently closed cards:

```
done: api-optimization, cutoff-tests — closed cards; open one before re-deciding in its area
```

- Without it a `done/` card has no automatic surface at all: the `doing/` loop skips it, so an agent
  only ever finds the archive by grepping for something it does not know exists.

## Checking that the record is still true

```bash
bash <this-skill>/scripts/verify-outcome.sh          # list what it would run
bash <this-skill>/scripts/verify-outcome.sh --run    # run and compare
```

- Walks every closed card's `## Outcome` table and runs the recorded command.
- `ok` when a `Verify` assertion exits 0. `DRIFT` when it does not. `FAIL` when the command errors.
- A row with no `Verify` cell is `LOOSE`: the recorded After text only has to appear in the output.
  Prose never does, so `LOOSE` never fails the run — it asks for an assertion instead.
- `manual` in the Verify cell skips the row: a deployed stage or a secret only a person has.
- Exit 1 only on a strict drift or a command failure. Nothing is modified, and commands only run
  with `--run`.

## Reading it back

A record nobody reads is a write-only file. Three commands are the read path:

```bash
grep -l -i "<the area>" flow-trail/{done,backlog}/*/README.md 2>/dev/null || true
bash <skill>/scripts/session-start.sh
bash <skill>/scripts/flow-trail-stats.sh
```

- The first runs before opening a card, over the archive and the parked pages.
- A closed card that already learned something should be cited, not rediscovered.
- A parked page in the same area is either the card about to be opened, or a line saying why not.
- The second runs every session, through the hook.
- The third is the only view of the whole board, and the only one that can say a card is not being
  used:

```
card                       column edited     finds   cited  rows strict  manual  lines
------------------------   ------ ---------- -----   ----- ----- ------ ------- ------
api-optimization           done   2026-11-18     5     4/5    12     11       1    109
login-refactor             doing  2026-11-18     3     2/3     2      0       0     68
```

- `cited 4/5` counts findings whose `Cited by` names something other than `nothing yet`.
- Below it, a second table reads `usage.md`: findings used, applied, falsified, first use, via. The
  first table is what the card points at; only the second is about retrieval.
- `usage.md` grows by one row per event: `flow-trail-usage.sh --add <card> <F#> applied "<what it
  changed>" --ref commit:<sha>`. How to read the result: [evals](evals.md).
- `strict` counts Outcome rows carrying a `Verify` assertion; `--verify` adds `ok/drift` and runs
  them.
- Nothing is written, and the table is not a file on purpose: a committed copy rots in the same way
  a line number does.

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
