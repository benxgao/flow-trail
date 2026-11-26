---
name: flow-trail
description: Track work that outlives one session on a three-column board whose columns are directories — `backlog/` for a one-page idea, `doing/` for a plan with phases and a measured baseline, `done/` for the conclusions. A card gains its evidence and state files when it starts and loses the state file at close, so the record keeps only what is still true. Every decision records the option that was rejected. Use when the user says "create a plan", "plan this", "write a plan for", "start a track", "track this work", "park this idea", or "how should we approach X" for anything larger than one sitting; when resuming work ("where were we", "continue"); when asked why something was decided; or when a repository already contains a flow-trail/ folder. It creates the folders and files itself — no copying, no setup. Not for one-commit fixes.
agent_created: true
---

# flow-trail

- A card is a folder in one of three columns: `backlog/`, `doing/`, `done/`.
- The column is the path, so a card moves with `git mv` and carries no status field.
- On "plan this", create the card in `doing/`. Do not answer with a plan in the conversation.
- The value is not the deleted scratch file. It is what moves out of it first.

## The three columns

| Column | A card holds | Leaves when |
| --- | --- | --- |
| `backlog/` | `README.md` — problem, trigger, sketch | someone starts it |
| `doing/` | `README.md`, `findings.md`, `progress.md` | every phase is verified |
| `done/` | `README.md`, `findings.md` | never |

- One card in `doing/`. A second is two things half-built; say which one is current.
- A lane directory appears the first time a card needs it. Do not create empty ones.
- `skips.md`, `usage.md` and the root `README.md` sit beside the columns, not in them.

## "Create a plan" means create the card

Triggers to act on, not to discuss:

- "create a plan", "plan this", "write a plan for X", "start a track", "track this work"
- "how should we approach X", when X will not fit in one session
- "where were we", "continue", whenever `flow-trail/doing/*/progress.md` exists
- any change where a number has to move and someone will ask by how much

Then, in this order, without asking permission:

1. Search the archive and the backlog.
   - `grep -l -i "<the area>" flow-trail/{done,backlog}/*/README.md 2>/dev/null || true`
   - A contradicting `## Lessons` line belongs in your `## Decisions`, citing that card.
   - A parked page in the same area is this card, or one line saying why it stays parked.
   - This is the only moment either is worth reading.
2. Name it. `flow-trail/doing/<card>/`, kebab-case, two to four words, naming the change.
   - Already in `backlog/`: `git mv backlog/<card> doing/<card>` and keep its page as the README.
   - No ticket number.
   - Ambiguous name: pick one, say so in a line, do not open a dialogue.
3. Write `progress.md` first, verbatim from template 1, replacing only `<...>`.
4. Measure the baseline before touching code.
   - Run the command, paste what it printed into the `Output` column.
   - A number copied from a document is `quoted from <path>`, and does not count.
5. Write `README.md` from template 2 with `## Contract` and one `## Decisions` row.
   - Write `findings.md` from template 3, header only.
   - Empty is the correct answer for a card that produced no evidence.
6. Reply in three lines: the path, the baseline measured, the first phase.

Never deliver a plan as a chat-only artifact, an in-conversation TODO list, or a loose `plan.md`.

- Those three shapes disappear when the session ends.
- Reconstructing one costs more than writing the files now.

### First card in a repository

- Create `flow-trail/README.md` from template 4.
- Create `flow-trail/skips.md` with the four-cell header from `Not worth a card` below.
- Create `flow-trail/usage.md` from template 6: an empty log with its four-cell header.
- Append the pointer below to `AGENTS.md`, or `CLAUDE.md`, whichever the repo uses.
- A board from `scripts/install.sh` already holds those files and the pointer: write only what is
  missing, and say which of them you had to add.
- A board with no `usage.md` was written before 0.3.0: add it from template 6 now, and expect
  findings older than 0.4.0 too. `scripts/flow-trail-lint.sh` names both, with the release.

```markdown
## Work tracking

Work larger than one commit is tracked in `flow-trail/` as a board: `backlog/`, `doing/`, `done/`.
Read `flow-trail/README.md` first.
Resume a card from `flow-trail/doing/<card>/progress.md`.
Deciding not to track a change is also a decision: one line in `flow-trail/skips.md`.
```

The pointer is what makes the next session find the folder. The skill only covers this one.

### Make it fire on its own

- A pointer is read only if the agent happens to look.
- Wire `scripts/session-start.sh` into the harness's session-start hook: `docs/hooks.md`.
- It prints the folder and each card's `next:` line, and nothing outside a project.

## Recording what you used

A closed card exists for a later task. When one of its findings actually changes what you do, that
event gets a row in `usage.md` — not in the card, because it happens after the card closed.

```bash
bash <this-skill>/scripts/flow-trail-usage.sh --add <card> <F#> applied \
  "one line: what it changed" --ref commit:<sha> --via grep
```

- Two kinds, and no third: `applied` (it changed what was done) and `falsified` (it was no longer
  true when someone relied on it).
- Reading a card is not an event, and a row whose `ref` does not resolve is not an event either:
  `commit:`, `test:` or `pr:` is the difference between a memory and a record.
- `--via` records how it was found — `grep`, `hook`, `readme`, `memory`. That column is the one
  worth debugging: it says which surface actually delivers a finding.
- No row at all is data too. `flow-trail-stats.sh` lists the findings nothing has used, which is
  either dead weight or an unfindable one, and those need different fixes.
- Two sessions appending at once conflict on the last line. Keep both rows; order is a nicety.

## Parking an idea

"Park this", "not now", "add to the backlog" — write `flow-trail/backlog/<card>/README.md` from
template 5.

- One page. No `progress.md`, no `findings.md`, no phases, no baseline.
- Name the trigger: the measurement or event that would move the card into `doing/`.
- Do not plan the work. A plan for work nobody is doing is a guess.
- Reply in one line: the path, and the trigger you wrote down.
- The page is edited while it waits: a leftover from a closed card, or a trigger that has moved,
  rewrites one line. Say which page, and what changed on it.

## Not worth a card

A one-commit change. Say so in one line and put the row in `flow-trail/skips.md`:

```
| Date | Change | Measured before | Why no folder |
| --- | --- | --- | --- |
| 2026-11-07 | rename `auth` middleware | 3 files, 0 tests touched | one commit, nothing to resume |
```

- An undocumented skip is how a record stops existing.
- Later nobody can tell "too small" from "nobody bothered".

## Template 1 — `progress.md` (deleted at close)

Copy verbatim into `flow-trail/doing/<card>/progress.md`.

````markdown
---
card: <card-slug>
status: open
phases:
  - { id: P1, name: "<first phase>", code: "[ ]", verified: "[ ]" }
  - { id: CL, name: "Close", code: "[ ]", verified: "[ ]" }
next: "<P1> — <the single next action, one line>"
---

# Progress: <card>

## Baseline

Measured **before the first edit**, with the command and what it printed. A row without an Output
was quoted from somewhere, not measured — mark it `quoted from <path>` so the next reader knows.

| Metric | Before | Command | Output |
| --- | --- | --- | --- |
| <what is counted> | <n> | `<command>` | <the line it printed> |

> If no baseline is possible, say why in one line. Never leave the section out.

## Phases

One phase touches **one layer** (schema → service → endpoint → client). A phase that crosses
layers cannot be verified or reverted on its own.
Order them so every phase leaves the repo runnable.

### P1 — <name>

**Goal**: <what this phase accomplishes, one sentence>

**Files**: `<path>` (create) — <why>; `<path>` (modify) — <what changes>

**Verify**:

```bash
<command>   # <expected output>
```

**Checklist**:

- [ ] **1.1 — <name>**: <work item>

### CL — Close

- [ ] Durable evidence moved to `findings.md`
- [ ] `## Outcome` carries Before, After and Command
- [ ] Every decision has a `## Decisions` row with its rejected alternative
- [ ] `## Residual` written; "nothing" is valid, silence is not
- [ ] Every earlier card this work used has a `usage.md` row; "none" is valid
- [ ] `git rm flow-trail/doing/<card>/progress.md`
- [ ] `git mv flow-trail/doing/<card> flow-trail/done/<card>`

## Session notes

Append-only, newest last. One entry when you stop, so the next session does not reconstruct what you
tried.

```markdown
### <YYYY-MM-DD HH:mm> — <Pn>.<m>

- Did: <what changed, by file or sub-item>
- Verified by: <command and result> — or `none`
- Used: <card F#> — <what it changed>, or `none` (a row in `usage.md` if not `none`)
- Tried and dropped: <what you attempted and why it failed; the most valuable line here>
- Next: <the single next action>
- Blocked on: <none | person / track / missing decision>
```
````

## Template 2 — `README.md` (the entry point, kept)

Copy verbatim into `flow-trail/doing/<card>/README.md`.

- Anyone opening the card reads this first.
- It points at `findings.md` for the detail.

````markdown
# Card: <the change in plain words>

<Two sentences: what was wrong before, what this does about it. No history of the investigation —
that belonged in `progress.md`, which is deleted at close.>

Detail behind these conclusions: [`findings.md`](./findings.md).

## Outcome

<Fill at close, or at planning with the numbers marked `planned` — the word is read by
`verify-outcome.sh`, which skips the row in `doing/` and fails it in `done/`. Three sentences at most,
then the table. The Command column is not optional: it is the only copy left once `progress.md` is
gone.
`Verify` is the optional strict form: one assertion that exits 0 while the After value is still
true. Without it the checker can only ask whether the After text appears in the output, which is
why a row written in prose reports DRIFT on a card that is perfectly healthy. Assert the behaviour
the row added — a test file — never a total: `=== 8` on a route count turns red the day someone
adds the ninth, which is a change the card wanted.>

| Metric | Before | After | Command | Verify |
| --- | --- | --- | --- | --- |
| <what is counted> | <n> | <n> | `<command that prints it>` | `<assertion; exit 0 means still true>` |

## Contract

<The invariants that **still hold now the work is done**, not the intentions it started with.
Drop anything the finished system no longer needs; a contract nobody can violate is decoration.>

1. **<name>.** <what holds, one sentence> — gate: `<command>` → `<expected>`.
2. **<name>.** <what holds> — *if broken*: <the revert or manual step that restores it>.

## Decisions

<One row per decision expensive to reconstruct: the choice, the reason, and **what was rejected**.
The rejected alternative is the part a reader cannot recover from the code.>

| Decision | Why | Rejected alternative | Enforced by |
| --- | --- | --- | --- |
| <what was decided> | <the reason, a number or `path:line`> | <what lost, and why> | `<path>` |

## Lessons

<Only entries where the next attempt would go differently — a concrete situation, not a principle.
`None yet.` is honest.>

- **<what happened>** — <the situation in one clause>. Next time: <the different action>.

## Residual

<What is unfinished, and where it now lives. Silence reads as "everything worked", which is
almost never true.>

- **<what is open>** — <where it went: a backlog card, a follow-up card, or "dropped: <reason>">.
- **<unproven claim>** — <what has never been run, and the command that would prove it>.

## Where the proof lives

<Point at things, do not copy them.>

| Question | Where |
| --- | --- |
| Does the behaviour still hold? | `<test file>` |
| How was it measured? | `<command>` |
| Why was it done this way? | `## Decisions` above |
| What did we actually see? | [`findings.md`](./findings.md) |
````

## Template 3 — `findings.md` (evidence, kept)

Copy verbatim into `flow-trail/doing/<card>/findings.md`.

- A finding is something you did not know before, that changes a decision, and that the repository
  cannot tell you. A number that only proves the work happened is a receipt, and receipts go at the
  bottom.
- If `grep` in this repo can rebuild the claim, it is not a finding: the code is the document, and a
  copy of it can only go stale. `src/DELETE has no caller` is a finding for a week; `the cap is
  100 KB` is a line of code wearing a heading.
- Ordered by what it costs the next reader **not** to know. Not by date: the expensive one is
  rarely the last one found.
- Every entry names what cites it, why the code cannot supply it, and how a reader will notice it
  has gone false. One with no way to notice is a liability, not evidence.
- A citation is a path plus a string that must still be in that file — `fixtures.ts :: function
  scopeToStage(` — never a line number. A line number is false after the next commit above it, and
  no check can tell a moved citation from a missing one. The linter greps the string.
- Empty is valid: a card that produced no evidence leaves the file empty.

````markdown
# Findings: <card>

What this card learned. Conclusions live in [`README.md`](./README.md). Ordered by what it costs a
reader **not** to know — not by when it was found. Each entry ends with what cites it, so a claim
that has stopped mattering can be found and retired instead of outliving its usefulness.

## F1 — <what you learned, as a sentence about the world>

- **Saw** (<date>, <where>) — <the observation, and the command or path that produced it>
- **Means** — <what it implies for the code or the plan>
- **Cost if unknown** — <what the next person would do instead, and how long it would take>
- **Not in the code because** — <why this repo cannot recover it; `derivable` is no answer>
- **Cited by** — `path :: a string still in that file`, `#F1` in the code, or `nothing yet`
- **Check** — `<command; exit 0 while the claim still holds>`, or
- **Dies when** — <the event that makes it false>. Exactly one of these two.

## Reference — <a table someone will look up>, verified <date>

<Only for a lookup table that outlives the card: a status map, a vocabulary, a set of limits. Where
the two endpoints disagree, say so in a column rather than averaging them into one row.>

| <what> | <value> | <where> |
| --- | --- | --- |
| <case> | <what happens> | `<path:line>` |

## Receipts

<Numbers someone may re-check, with the command and the date. Name what you deleted and why, so the
next author does not put it back.>

| What | Command | Output | Date |
| --- | --- | --- | --- |
| <what was measured> | `<command>` | <the line it printed> | <date> |
````

## Template 4 — the folder note `flow-trail/README.md`

Written once per repository, so a human who finds the directory can read it.

````markdown
# flow-trail

Work larger than one commit is tracked in this folder as a board. Three columns, one card per
initiative, plain markdown in git; no tool, no database, no CI.

| Path | A card holds | Lives until |
| --- | --- | --- |
| `backlog/<card>/README.md` | Problem, trigger, sketch — one page, no plan | someone starts it |
| `doing/<card>/README.md` | Conclusions — the six headings | forever |
| `doing/<card>/findings.md` | Evidence behind them | forever |
| `doing/<card>/progress.md` | State — phases, baseline, session log | deleted at close |
| `done/<card>/` | The same card, closed: README and findings | forever |
| `skips.md` | Changes deliberately not tracked, with the reason | forever |
| `usage.md` | Later tasks that actually used a finding | forever |

The column is the folder, so a card is moved, never copied:

```bash
git mv backlog/<card> doing/<card>              # start
git rm doing/<card>/progress.md                 # close
git mv doing/<card> done/<card>                 # close
```

`progress.md` exists only while a card is in `doing/`. Closing distils: conclusions to `README.md`,
evidence to `findings.md`, state deleted.

If closing needs a summary pass, the README was not being written while the work happened.

The protocol — how to open a card, the markers, what to measure — is the `flow-trail` skill:
https://github.com/benxgao/flow-trail
````

## Template 5 — the backlog card `backlog/<card>/README.md`

One page. No state file, no phases, no baseline — nobody has started, so nothing is measurable.

````markdown
# Backlog: <the idea in plain words>

<One paragraph: what is wrong or missing now, and what would be different. No history of how the
idea arrived.>

- **Trigger** — <the measurement or event that moves this card into `doing/`>
- **Sketch** — <the smallest change that would show it works, one or two lines>
- **Waits on** — <the reason it is not being built: cost, a dependency, a decision not made>

## Decisions

<Drop this section when writing the idea down forced no choice.>

| Decision | Why | Rejected alternative |
| --- | --- | --- |
| <the shape the idea was written in> | <why that shape> | <what lost> |
````

## Template 6 — `usage.md` (the log, kept)

Written once per repository, beside the columns. `flow-trail-usage.sh --init` writes it; every
`--add` appends one row.

````markdown
# Usage

One row each time a later task actually used a finding from a card. Append-only; the newest row
goes last, so a diff shows only what was added.

Reading a card is not usage, and neither is a row without a ref that resolves. Two kinds:

- `applied` — the finding changed what was done.
- `falsified` — the finding was no longer true when someone relied on it.

`via` records how it was found, which is the part worth debugging: `grep`, `hook`, `readme`,
`memory` (remembered without reading — plausible, and worth a second look).

| Date | Card | Finding | Kind | Via | Ref | What it changed |
| --- | --- | --- | --- | --- | --- | --- |
````

## While working

- The column says where the card is. The phase list says where the work is.
- Status lives in `progress.md` front-matter `phases`, and nowhere else.
- No second dashboard. No progress line in the body.

| Marker | Meaning | Who acts |
| --- | --- | --- |
| `[ ]` | not started | — |
| `[~]` | being written now | agent |
| `[v]` | written, **not** verified | whoever can run the command |
| `[x]` | verified by running it | — |
| `[!]` | blocked, needs a person | named owner |
| `[-]` | dropped, reason on the same line | — |

Where things go. Writing to the wrong file is how a card becomes unreadable:

| What you have | Goes to | Because |
| --- | --- | --- |
| a choice, and what lost | `README ## Decisions` | the code never shows the rejected option |
| a number, and its command | `Baseline` → `Outcome` | a number without a command is a story |
| a finding, what it costs, what cites it | `findings.md ## F<n>` | the reader decides in one line whether to keep reading |
| a number that only proves work happened | `findings.md ## Receipts` | it answers no question the next reader has |
| a later task that used a finding | `usage.md` | the event happens after the card closed |
| state, next action, what you tried | `progress.md` | all of it expires |

- `code` and `verified` are separate facts. Never write `[x]` because the code compiles.
- A decision gets its row the session it is made.
- A session note when you stop: did / verified by / tried and dropped / next / blocked on.
- The "tried and dropped" line is the one a later reader cannot reconstruct.

## Close

Closing is a distillation, not a tidy-up. Three moves:

1. Evidence out of the log. Each finding becomes an `F` entry: what was seen, what it implies, what
   it costs to not know, and what cites it. Numbers that only proved work happened go under
   `## Receipts`, dated.
2. Conclusions out of the log.
   - `## Outcome` carries Before, After and the Command.
   - Every decision has its row and its rejected alternative.
   - `## Residual` names what is open, and the page each leftover lands on.
   - Edit those pages in the same session; a leftover that waits for a later session is lost.
3. Delete. `git rm flow-trail/doing/<card>/progress.md`, then `git mv` the card into `done/`.

- No summary pass. If closing needed one, the README was not written while the work happened.
- `findings.md` stays, capped at ~200 lines. Past the cap the bulk becomes a conclusion.

## The five rules, and what each one prevents

| Rule | Prevents |
| --- | --- |
| Measure before touching, with the command and its output | "down 50%" with no before-number |
| `[v]` and `[x]` are different states | "done" meaning "compiles" |
| Every decision records the rejected option | a reader who sees what was chosen, never why |
| Three files by role; only the state dies | a scratch file outliving the work |
| A rule no command can check gets deleted | ceremony that reads as compliance |

## Lint (optional)

```bash
bash <this-skill>/scripts/flow-trail-lint.sh flow-trail
```

- Twenty checks: a card in `doing/` has both files, no `progress.md` in `done/`, six headings.
- And: no surviving checkbox, a backlog card carries no `progress.md`, skip rows have four cells.
- And: findings is linked from its README, every findings heading is `## F<n> —` plus an optional
  `## Reference` and `## Receipts`, each `F` entry carries `Cost if unknown` and `Cited by`.
- And: each entry carries `Not in the code because` — the admission test — and one of `Check` or
  `Dies when`, so a claim that can no longer be true is noticed instead of believed.
- And: every citation resolves — `path :: needle` names a file that exists and a string still in
  it, which is why a citation is not a line number.
- And: no `Enforced by` cell points at `progress.md`, which is deleted at close.
- And: every `usage.md` row names a card and a finding that exist, with a `ref` that resolves.
- Six warnings: closed README 120 lines, findings 200, more than one card in `doing/`, a card with
  no `usage.md` beside it (the log arrived in 0.3.0), a closed card unused for
  `FLOW_TRAIL_SILENT_DAYS` (default 30), and a citation written as `path:line`, which nothing can
  check.
- Reports, exits 1, gates nothing. No skill directory? Skip it.
- Templates in this file: `bash <this-skill>/scripts/template-lint.sh`.
  Prose lint skips fenced blocks, so nothing else checks what a verbatim copy inherits.

## Read the board (optional)

```bash
bash <this-skill>/scripts/flow-trail-stats.sh            # one row per card
bash <this-skill>/scripts/flow-trail-stats.sh --verify   # and re-run every Outcome command
```

- Columns: `edited`, `finds`, `cited`, `rows`, `strict` (rows with a `Verify` assertion), `manual`.
- A second table counts events from `usage.md`: findings used, applied, falsified, first use, via.
- `cited` is what the card points at; `used` is what a later task actually consumed. Only the second
  is about retrieval, and only `usage.md` carries it.
- `--verify` adds an `ok/drift` column and executes the recorded commands; the rest reads files.
- Do not commit a copy of this table. It would go stale exactly like a line number does: the
  command is the document.

## Verify the record (optional, any time)

```bash
bash <this-skill>/scripts/verify-outcome.sh --run
```

- Re-runs every command in the `## Outcome` tables of `done/` **and** `doing/`.
- A row whose After says `planned` is `plan`: nothing has been measured, so nothing to verify —
  and a number still `planned` in a closed card is a DRIFT, because that card claims a measurement
  it never took.
- Reports `ok`, `LOOSE`, `skip`, `DRIFT`, `FAIL`; exits 1 on a strict drift or a command failure.
- A row with a `Verify` assertion is strict: exit 0 is `ok`, anything else is `DRIFT`.
- A row without one is `loose`: it only asks whether the After text appears in the output. A `loose`
  DRIFT asks you to write the assertion, not to doubt the card.
- Without `--run` it only lists what it would run.
- This is why the Command column exists.

## Files

- `scripts/` — the installer, the linter, the hook, the usage log, the stats table, the outcome
  check, the prose check.
- `docs/` — `install.md` (per harness), `hooks.md` (wiring), `how-it-works.md` (mechanics),
  `writing.md` (house style).
- `docs/faq.md` — the answers kept off the README: cost, merges, two people, a dead rule.
- `examples/login-refactor/` — a board mid-flight, with a runnable `app/`.
- `.claude-plugin/` — the manifest that makes `npx skills add` and `/plugin marketplace add` work.

## What it deliberately does not have

- No dashboard, board UI, score, drill, mandatory closing phase or CI gate.
- No status field beside the folder. The column is the path, so it cannot go stale.
- Each removed rule was measured in the source repo: 0 completions in 7 plans, 1 drill in 11.
- Deleted rather than tuned. Do not add one back without a measurement.
