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
