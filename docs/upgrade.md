# Upgrade

Upgrade through your agent, not by hand. The right command depends on which route installed the
skill, and only the agent can read that off the disk before choosing. Paste this with the
repository open:

```text
Upgrade flow-trail in this repository:
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/benxgao/flow-trail/HEAD/scripts/bootstrap.sh)"
Show me the whole output, and the two lines it ends with: installed and verdict.
Do not edit AGENTS.md, .gitignore or flow-trail/ yourself.
Then tell me the release I am on, and the sentence that opens the next card.
```

- It asks the remote for its newest tag, then reads the version this repository has, then moves
  only the owner it finds: `npx skills update` for a copy, a checkout plus `install.sh` for a link.
- The last two lines are read back from the manifest. A download that did not land says so instead
  of ending on `up to date`.
- `--dry-run` first prints that plan and writes nothing. `--main` follows the tip of the default
  branch instead of the newest tag.
- Read it before running it: one file, `git` and the installer, nothing else. It fetches from the
  default branch so its logic is never a stale copy — the failure this page is about.

## By hand

The same two routes, typed. Pick by what the repository has:

| The repository has | Run |
| --- | --- |
| `skills-lock.json` and a copy in `.agents/skills/` | `npx skills update flow-trail -y -p` |
| a link into `~/.flow-trail` | `git -C ~/.flow-trail fetch --tags`, then `install.sh --relink` |

- Neither command prints a version, and both exit 0 when they changed nothing. Read the manifest.
- Measured on 0.1.2 → 0.6.1: 20 files rewritten, 6 created, and the whole output was four lines
  ending in `✓ All project skills are up to date`. The same four lines appear when there is
  nothing to do.
- The run leaves a zero-byte `skills-lock.json.lock` in the repository root. Delete it; it is a
  lock file, not part of the install.

## Which release is installed

```bash
sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' .agents/skills/flow-trail/.claude-plugin/plugin.json
# 0.7.0
```

- The manifest is the only file that carries a version. `npx skills list` prints the path without
  one, and `skills-lock.json` records a commit, which is not a release anyone can name.
- For the installer route the same line works on `~/.flow-trail/.claude-plugin/plugin.json`.
- `CHANGELOG.md` in the installed folder is the upstream file: its top heading is the same answer.

## Two owners, and an upgrade moves only one

| Installed by | On disk | Moved by |
| --- | --- | --- |
| `npx skills add benxgao/flow-trail` | `<repo>/.agents/skills/flow-trail`, a copy, commit in `skills-lock.json` | `npx skills update flow-trail` |
| `scripts/install.sh` | `~/.agents/skills/flow-trail` and one link per harness, to `~/.flow-trail` | `git -C ~/.flow-trail fetch --tags`, then `--relink` |

- A harness that reads both folders reads the copy. Upgrade the other owner and the old release
  keeps answering, with no line anywhere saying which version is in charge.
- The two routes have two notions of current: `npx skills update` follows the default branch, and
  `bootstrap.sh` checks out the newest tag. Between a merge and its tag they disagree, by design.
- `install.sh` prints a `project` line when a project copy is not the version it is installing,
  with both numbers. `--relink` replaces a copy in a harness folder; it leaves a project copy
  alone, because that copy belongs to `npx skills`' lock file, not to the installer.

## The cards

The skill is files. The cards are records. An upgrade replaces the first and leaves the second in
the shape of the release that wrote it — which is the part that breaks, and the part no command
mentions.

The installer adds a missing `usage.md` and names the row an old folder note lacks. It does not
edit a card: those are the record, and they belong to whoever wrote them.

| Release | What a card had to gain | Reported as |
| --- | --- | --- |
| 0.2.1 | `## Measurements` becomes numbered `## F<n> —` findings, each with `Cost if unknown` and `Cited by`; `## Outcome` gains a `Verify` column | E8, E9 |
| 0.2.2 | `Cited by` names `path :: a string`, not `path:line` | E11 for a dead needle, W4 for a line number |
| 0.3.0 | `usage.md` beside the columns; `Used:` in the session log; a `usage.md` row in the folder note | the installer's `board` line, and W6 until it is fixed |
| 0.4.0 | each finding gains `Not in the code because` and exactly one of `Check` / `Dies when` | E13, E14 |
| 0.5.0 | nothing in the card; `area` is counted from the citations | — |
| 0.6.x | nothing in the card | — |

The migration list is the linter:

```bash
bash .agents/skills/flow-trail/scripts/flow-trail-lint.sh flow-trail
```

- Every error names a card and a rule; this table says which release asked for it.
- The `Verify` column has no lint check. A row without it is `LOOSE` in `verify-outcome.sh`, which
  is how the rows still worth filling are found.
- Migrate the findings you still cite and delete the rest. The admission test arrived with 0.4.0
  and applies to the old rows too: two new fields on a finding the code can rebuild make a cache
  that can only lie.
- A card in `doing/` is the one to migrate now, because the next session reads it. A closed card
  can wait; the lint names it again the moment something cites it.

## After an upgrade

```bash
bash <skill>/scripts/flow-trail-lint.sh flow-trail    # 0 error, 0 warning
bash <skill>/scripts/flow-trail-stats.sh              # the usage line is a count, not a promise
bash <skill>/scripts/verify-outcome.sh --run          # every Outcome row still true
```

- `usage: 0 events across N commit(s)` is the normal first line after 0.3.0. Rows appear from the
  next task that reads a finding, not from the upgrade.

## What an upgrade does not touch

- `AGENTS.md`: the pointer is checked by the phrase `flow-trail/README.md`, not by wording, so a
  pointer written by 0.1.2 keeps its sentences and is reported `(already there)`.
- The folder note `flow-trail/README.md`: reported when a row is missing, never rewritten. Delete
  it and re-run to regenerate it with the current rows.
- The cards, for the reason above.

## Where the scripts are

Every other page writes `~/.flow-trail/scripts/…`, which exists only after the installer route.

| Installed by | Prefix for `flow-trail-lint.sh`, `flow-trail-stats.sh`, `verify-outcome.sh` |
| --- | --- |
| `npx skills` | `<repo>/.agents/skills/flow-trail/scripts/` |
| `scripts/bootstrap.sh`, `install.sh` | `~/.flow-trail/scripts/` |
