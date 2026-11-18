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
- `skips.md` and the root `README.md` sit beside the columns, not in them.

## "Create a plan" means create the card

Triggers to act on, not to discuss:

- "create a plan", "plan this", "write a plan for X", "start a track", "track this work"
- "how should we approach X", when X will not fit in one session
- "where were we", "continue", whenever `flow-trail/doing/*/progress.md` exists
- any change where a number has to move and someone will ask by how much

Then, in this order, without asking permission:

1. Search the archive.
   - `grep -l -i "<the area>" flow-trail/done/*/README.md 2>/dev/null || true`
   - A contradicting `## Lessons` line belongs in your `## Decisions`, citing that card.
   - This is the only moment the archive is worth reading.
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
- Append the pointer below to `AGENTS.md`, or `CLAUDE.md`, whichever the repo uses.
- A board from `scripts/install.sh` already holds both files and the pointer: write only what is
  missing, and say which of the three you had to add.

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

## Parking an idea

"Park this", "not now", "add to the backlog" — write `flow-trail/backlog/<card>/README.md` from
template 5.

- One page. No `progress.md`, no `findings.md`, no phases, no baseline.
- Name the trigger: the measurement or event that would move the card into `doing/`.
- Do not plan the work. A plan for work nobody is doing is a guess.
- Reply in one line: the path, and the trigger you wrote down.

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
- [ ] `git rm flow-trail/doing/<card>/progress.md`
- [ ] `git mv flow-trail/doing/<card> flow-trail/done/<card>`

## Session notes

Append-only, newest last. One entry when you stop, so the next session does not reconstruct what you
tried.

```markdown
### <YYYY-MM-DD HH:mm> — <Pn>.<m>

- Did: <what changed, by file or sub-item>
- Verified by: <command and result> — or `none`
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

<Fill at close, or at planning with the numbers marked `planned`. Three sentences at most, then the
table. The Command column is not optional: it is the only copy left once `progress.md` is gone.
`Verify` is the optional strict form: one assertion that exits 0 while the After value is still
true. Without it the checker can only ask whether the After text appears in the output, which is
why a row written in prose reports DRIFT on a card that is perfectly healthy.>

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

- A finding is something you did not know before, and that changes a decision. A number that only
  proves the work happened is a receipt, and receipts go at the bottom.
- Ordered by what it costs the next reader **not** to know. Not by date: the expensive one is
  rarely the last one found.
- Every entry names what cites it. One that nothing cites is the first candidate for retirement.
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
- **Cited by** — `<path:line>`, or `#F1` markers in the code, or `nothing yet`
- **Status** — <fixed / kept / still open, one clause>

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
   - `## Residual` names what is open.
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

- Thirteen checks: a card in `doing/` has both files, no `progress.md` in `done/`, six headings.
- And: no surviving checkbox, a backlog card carries no `progress.md`, skip rows have four cells.
- And: findings is linked from its README, every findings heading is `## F<n> —` plus an optional
  `## Reference` and `## Receipts`, each `F` entry carries `Cost if unknown` and `Cited by`.
- And: no `Enforced by` cell points at `progress.md`, which is deleted at close.
- Three warnings: closed README 120 lines, findings 200, more than one card in `doing/`.
- Reports, exits 1, gates nothing. No skill directory? Skip it.
- Templates in this file: `bash <this-skill>/scripts/template-lint.sh`.
  Prose lint skips fenced blocks, so nothing else checks what a verbatim copy inherits.

## Verify the record (optional, any time)

```bash
bash <this-skill>/scripts/verify-outcome.sh --run
```

- Re-runs every command in the closed cards' `## Outcome` tables.
- Reports `ok`, `LOOSE`, `skip`, `DRIFT`, `FAIL`; exits 1 on a strict drift or a command failure.
- A row with a `Verify` assertion is strict: exit 0 is `ok`, anything else is `DRIFT`.
- A row without one is `loose`: it only asks whether the After text appears in the output. A `loose`
  DRIFT asks you to write the assertion, not to doubt the card.
- Without `--run` it only lists what it would run.
- This is why the Command column exists.

## Files

- `scripts/` — the installer, the linter, the hook payload, the outcome check, the prose check.
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
