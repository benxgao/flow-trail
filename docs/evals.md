# Proving the record works

A card is a claim about the future: "someone doing this again will be faster or wrong less often
because of what is in here." Re-reading the card cannot test that claim. Three things can.

1. **An event log.** `usage.md` records the moment a finding changed what a later task did.
2. **A denominator.** How many findings exist, so "3 uses" has something to be 3 of.
3. **A control.** One finding you know is wrong, so "nobody complained" stops being evidence.

`flow-trail-stats.sh` prints 1 and 2. This page is about reading them, and about 3.

## What earns a place

The folder is only worth maintaining for what the repository cannot say. Sort every candidate claim
into one of four classes; two of them are findings.

| Class | Example | Can this repo tell you? | Rots? | Where it goes |
| --- | --- | --- | --- | --- |
| Landmine | MailerLite answers 200 on a repeat add | no — a live probe only | yes, if upstream changes | a finding with `Dies when` |
| Judgement | the `ttl` argument is ignored | the fact, not the verdict | no | a finding with `Check` |
| Why-not | envelope unification was rejected | no — the loser left nothing | no | `## Decisions`, not findings |
| Restatement | the body cap is 100 KB | yes, `grep MAX_BODY_BYTES` | the moment it changes | delete it |

- A **landmine** is a fact about the world outside the repo, and reading our code cannot produce it.
- A **judgement** is a fact the code holds plus the verdict "this is wrong", and the verdict is the
  part that costs a day to rebuild.
- A **why-not** is history. It has its own table, and a finding is the wrong place for it.
- A **restatement** is a cache of the code with no upside and one failure mode: it lies after the
  next commit. This class is why people stop trusting the folder, and the lint cannot detect it —
  only the author can, by answering `Not in the code because` honestly.

`Not in the code because` is the admission test. If the honest answer is "you grep it and you know",
the finding must be deleted, not written.

## Why an agent reads this instead of the code

Two reasons, and neither is "documentation is good".

- **Code answers questions; it does not raise them.** Nothing in `src/` suggests the question "does
  MailerLite drop fields the workspace has not defined?". A reader who does not already suspect it
  will never grep for it, and the bug stays. The finding is a question someone already paid for.
- **Cost.** Rebuilding one runtime fact means reading the handler, the integration client, the
  fixtures and a test that does not exist yet. The finding is eight lines. That is the whole
  trade, and it is measurable: `cost per use` in the table above.

The trade fails when the eight lines can be replaced by one grep. That is the restatement class, and
deleting it is the maintenance.

## The maintenance budget

A finding is written once, in the session that discovered it, and never edited afterwards. Two
things touch it later, and both are triggered by a command rather than by discipline:

1. Its `Check` fails, or its `Dies when` happens. Re-derive, then rewrite the row as a `falsified`
   event and delete the claim.
2. `usage.md` says nobody used it in 90 days and it is greppable. Delete the row.

Nothing else. There is no review cadence, no owner, and no "keep the docs up to date" chore, because
a chore with no trigger is the thing that turns a folder into a liability.

## The three states

Every finding is in exactly one state, and the log is the only thing that tells them apart.

| State | Looks like | What it usually means |
| --- | --- | --- |
| applied | at least one `applied` row | the finding paid for itself |
| falsified | a `falsified` row | it was true when written and is not now |
| silent | no row at all | dead weight, or nobody can find it — different fixes |

Silent is not a verdict. It is the state that needs a question asked.

## Four numbers, and what each one is for

| Number | How | Read it as |
| --- | --- | --- |
| hit rate | findings with ≥1 `applied` / all findings | is the card reaching anyone |
| precision | `applied` / (`applied` + `falsified`) | was the record right when it was used |
| lag | days from close to first `applied` | under a week: an onboarding note. Months: a landmine warning |
| cost per use | findings lines / `applied` events | 200 lines to save one hour is a bad trade |

Rates on three events mean nothing. Below roughly ten events per card, read the rows instead of the
numbers, and treat the table as an index to the log.

## Silence, and the two fixes

A silent finding is either useless or unfindable, and the log cannot say which. Ask it directly:

1. Write the question a future reader would actually type, in their words, not the card's.
2. `grep -rn "<that question's keywords>" flow-trail/` and count the calls until the finding is on
   screen. More than three, or never: unfindable.
3. Found in one or two calls and still unused after months: dead weight.

The two outcomes get opposite repairs. Unfindable means the heading, the wording or the `Cited by`
anchor is wrong. Dead weight means deleting the finding, which makes the next card better.

## The control: plant a wrong finding

Every other number here is self-reported by the same agent that did the work. A log that only
records `applied` cannot distinguish a reader from a nodding one. So once a quarter:

1. Add one finding to a card that will plausibly be opened, marked in the body as a canary and
   dated: `<!-- canary, remove after 60 days -->`. Give it a real `Cost if unknown` so it is
   tempting, and make the claim false in a way a careful reader can check.
2. Wait. Note the date.
3. Score it. A `falsified` row within the window means the loop is read. Nothing, after a card that
   was opened, means the pipeline is producing text nobody checks.

Without this, "we had 12 applies this quarter" is unfalsifiable: the same number comes from a
working loop and from agents flattering the record.

## The audit

`flow-trail-usage.sh --check` resolves every `ref`: a `commit:` must exist, a `test:` must exist.
The linter runs it (E12), so a fabricated row fails the build of the record.

What it cannot check is whether the commit shows what the row claims. So once a month, take three
rows and read the commit. If a note and its commit disagree, the note is what is wrong — fix the
row, do not delete it, because the disagreement is itself the finding.

## What the numbers tell you to change

| Reading | Change |
| --- | --- |
| precision under ~80% | the card needs a `Verify` assertion or a date, not more prose |
| hit rate 0 after 90 days, and greppable | delete the finding; a shorter card is a better card |
| hit rate 0 after 90 days, and not greppable | rewrite the heading in the words a reader would use |
| lag under a week for every finding | this is onboarding, not memory — belongs in `CONTRIBUTING.md` |
| `via` is almost always `memory` | nobody is reading; the hook line is decoration, not retrieval |
| `via` is almost always `hook` | the session-start line is doing the work the README should do |

## What this design gives up

- **It is not real time.** A row is written when a session ends, so a use that is never recorded is
  invisible. Nothing in git can fix that; only a lower-friction habit can.
- **It records applications, not reads.** A finding that shapes a decision without the reader
  noticing leaves no row. Under-counting is the bias, on purpose: a log of reads drowns.
- **Appends conflict.** Two sessions writing the same minute collide on the last line. Keep both
  rows.
- **A row can be wrong.** The `ref` makes it expensive to be wrong, not impossible. That is what the
  monthly audit is for.
