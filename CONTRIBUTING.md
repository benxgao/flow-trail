# Contributing

- This repository is a workflow, not a program.
- Most of it is prose, and prose gets worse when many people add to it.
- So the bar is higher, and the bar is written down.

## The one rule

**A change cites a measurement or a run.**

- Not a preference. Not a best practice. Not "other trackers do this".
- New rule: say what breaks without it, and how you noticed.
- Changed rule: say what the old one cost. A count, a timestamp, a quote from a transcript.
- Deleted rule: the easiest to accept. A rule that never fired is decoration.

## What will be refused

Politely, without negotiation:

- **New mandatory phases, checklists or closing ceremonies.**
  - Four mandatory closing phases were completed 0 times in 7 plans.
- **Dashboards, scores, burndown, story points.**
  - Nothing in the repository can read them.
  - The board is `ls flow-trail/`; it is not maintained, so it cannot go stale.
- **A CI gate.**
  - The linter reports and exits 1. It is wired into nothing, on purpose.
  - A rule that needs a gate to be followed is a rule nobody wanted.
- **A second place to write state.**
  - Status lives in one place: the `progress.md` front matter.
  - The column is the folder. Nothing writes it down twice.
  - Two places is how the previous version ended up with three copies, all different.
- **Vendored dependencies.** Everything is bash and markdown.

## Testing a change

No test suite. Two things to run.

```bash
# 1. the linter against a deliberately broken fixture
mkdir -p /tmp/fx/flow-trail/{doing/demo,doing/second,done/stale,backlog/idea}
bash scripts/flow-trail-lint.sh /tmp/fx/flow-trail   # expect exit 1

# 2. the prose check over the docs you touched
bash scripts/prose-lint.sh
```

Then the real check: run the skill on a real project, for one piece of work, and report:

- Did it create the files without being asked?
- Was the baseline a real measurement, or a number copied from a doc?
- Did it distil at close, or only delete the scratch file?

That report is worth more than any review.

## Style

- Every doc follows [`docs/writing.md`](docs/writing.md): lists, not prose.
- `SKILL.md` under 430 lines, of which ~210 are the five templates.
- Each template under 70 lines. Each script under 100.
- A pull request past one of those says what it removed.

## Commits

- Imperative subject, one line, what changed and why it was needed.
- Body optional.

```
Require the baseline to carry its output, not just the command
```

## Where the reasoning lives

- [Design notes](references/design-notes.md) holds the measurement behind every rule.
- Read it before arguing with a rule. The argument may already be there.

## Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
