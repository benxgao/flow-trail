# Try it in sixty seconds

This folder is a board mid-flight, not a mock-up: `app/` runs, and `npm test` fails on the case the
last session wrote and never ran.

```bash
git clone https://github.com/benxgao/flow-trail.git ~/src/flow-trail
npx skills add benxgao/flow-trail -g
cd ~/src/flow-trail/examples/login-refactor
```

Open your assistant there and ask:

> where were we?

The answer should name the column the card sits in, the open phase, the decision that lost, and the
next action on file. Then check it:

```bash
cd app && npm test     # 5 tests, 4 pass, 1 fail
```

The failure is the open item the files warned about. The record named what would break and where,
before you ran anything.

## The board in here

| Column | Card | State |
| --- | --- | --- |
| `backlog/` | `export-csv` | one page, waiting for enough closed cards to export |
| `doing/` | `login-refactor` | P2 written, not run; `next: npm test` |
| `done/` | `cutoff-tests` | closed: README and findings, no `progress.md` |

## What is in here

| Path | Holds |
| --- | --- |
| `flow-trail/README.md` | The board: three columns, one card per initiative |
| `flow-trail/backlog/export-csv/README.md` | An idea with no plan behind it |
| `flow-trail/doing/login-refactor/` | Conclusions, evidence, and the state file |
| `flow-trail/done/cutoff-tests/` | A closed card: two files, `progress.md` deleted |
| `flow-trail/skips.md` | Two changes deliberately not tracked |
| `AGENTS.md` | The pointer the next session needs |
| `app/` | The service the card is about, `node --test`, no deps |

## Trying it on your own project

```bash
cp -r flow-trail AGENTS.md /path/to/your/project/
cd /path/to/your/project && npx skills add benxgao/flow-trail -g
```

Then delete the three example cards and say "plan the thing you were about to do anyway".
