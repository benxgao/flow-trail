# Install

One paste at your agent, or the same command typed by you. Both end in the same place: the newest
release, detected rather than named.

## Install with your agent

Paste this into the agent, with the repository open:

```text
Install flow-trail in this repository.

1. Run, from the repository root:
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/benxgao/flow-trail/HEAD/scripts/bootstrap.sh)"
2. Show me the whole output.
3. Do not edit AGENTS.md, .gitignore or flow-trail/ yourself: the installer writes those.
4. Tell me the version its last line reports, and the sentence for opening the first card.

If it cannot reach the remote, report what it printed and stop. Do not install by another route.
```

- The agent runs it and reports. The last two lines are `installed <version>` and a `verdict`.
- The output is a list of paths it changed, `(already there)` for the ones it did not.
- Nothing to configure after: no pointer to write, no ignore rule to add, no folder to create.

## Install by hand

The same command, typed by you at the repository root:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/benxgao/flow-trail/HEAD/scripts/bootstrap.sh)"
```

- `--dry-run` prints the release it found, the owner it would move, and writes nothing.
- `--main` follows the tip of the default branch instead of the newest tag.
- Re-run it any time: it is also the upgrade. Already current comes back `already <version>`, with
  the links and the board re-checked. [upgrade.md](upgrade.md) has the long version.
- The flags need a file rather than a pipe: `git clone -q --depth 1
  https://github.com/benxgao/flow-trail /tmp/flow-trail`, then
  `bash /tmp/flow-trail/scripts/bootstrap.sh --dry-run <repo>`.
- From a checkout you keep instead: `bash ~/.flow-trail/scripts/install.sh --relink`, which needs
  a `fetch --tags` first and prints no version of its own.

## What it writes

| Path | What goes there | Left alone when |
| --- | --- | --- |
| `~/.flow-trail` | the newest release, checked out at its tag | that tag is already checked out |
| `~/.agents/skills/flow-trail` | a link to `~/.flow-trail` | the link already points there |
| `~/.claude/skills/`, plus one per harness here | the same link | that harness is missing |
| `AGENTS.md` | the pointer, added as a section | it already names `flow-trail/README.md` |
| `CLAUDE.md`, `GEMINI.md` | the same block | the repository has no such file |
| `.gitignore` | `.agents/skills/`, `.claude/skills/` when present | the path is already ignored |
| `flow-trail/README.md` | the folder note — template 4 of `SKILL.md` | the file exists; an older one is reported, not rewritten |
| `flow-trail/skips.md` | the four-cell header | the file exists |
| `flow-trail/usage.md` | the empty log — template 6 | the file exists |

- The pointer is the part that makes the next session find the board; the skill alone does not.
- `~/.flow-trail` is a dependency checkout, not your work: it sits detached at the tag, and an
  edit there is replaced by the next run.
- The ignore lines are a guard: a skill's source is a dependency, not your project's code.
- The skill's source in a commit is the failure this prevents; the installer names the undo
  (`git rm -r --cached .agents/skills`) when it finds those files already tracked.
- No lane directory is created: `backlog/` and the others appear when a card needs them.

## Check it worked

```bash
ls -l ~/.agents/skills/flow-trail        # a link to ~/.flow-trail
grep -c 'flow-trail/README.md' AGENTS.md # 1
ls flow-trail/                           # README.md  skips.md  usage.md
sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' ~/.flow-trail/.claude-plugin/plugin.json
```

- The second run is the test: every line comes back `(already there)`.
- A harness that does not list the skill reads a different folder — the table below.

## Where a harness reads the skill

| Harness | Folder |
| --- | --- |
| Claude Code, GitHub Copilot CLI | `~/.claude/skills/` |
| Codex | `~/.agents/skills/`, and the older `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/`, alias `~/.agents/skills/` |
| WorkBuddy | `~/.workbuddy-ai/skills/` |
| CodeBuddy | `~/.codebuddy/skills/` |
| DeepSeek Harness | `~/.dsh/skills/`, `~/.agents/skills/` |
| Cursor, Windsurf, Roo Code, Qoder, Trae | none — `AGENTS.md` is the whole integration |
| Aider | none — `read: AGENTS.md` in `.aider.conf.yml` |
| Cline | `ln -s AGENTS.md .clinerules` |

- Per project instead: the same link at `.agents/skills/flow-trail`; the ignore lines cover it.
- Scan depth is one folder: `skills/flow-trail/SKILL.md` is found, a nested copy is not.
- Windows needs WSL or Git Bash: the installer uses symlinks.

## What the installer leaves to you

| Harness | The rest |
| --- | --- |
| Claude Code | hook in `.claude/settings.json`; it reads `CLAUDE.md` |
| WorkBuddy | restart the app after the first install |
| Trae | turn on the AGENTS.md option in its rules settings |
| Qoder | `AGENTS.local.md` for rules you keep out of git |
| Claude Code plugin route | `/plugin marketplace add benxgao/flow-trail`, untested |

## The hook, optional

- A pointer is read only if the agent looks. The hook prints the board before the first message.
- Test the payload first: `bash ~/.flow-trail/scripts/session-start.sh`
- Silent outside a project that has a `flow-trail/` folder. Per harness: [hooks.md](hooks.md).

## The scripts, optional

```bash
bash ~/.flow-trail/scripts/flow-trail-lint.sh flow-trail   # card shape, twenty checks
bash ~/.flow-trail/scripts/verify-outcome.sh --run         # re-run closed cards' Outcomes
bash ~/.flow-trail/scripts/flow-trail-stats.sh             # one row per card
```

- They report and exit 1. None gates a commit, and the skill never calls them.
- `flow-trail-stats.sh --verify` runs the middle one on every card and adds a column.
- Those paths exist after the installer route. After `npx skills`, `~/.flow-trail` was never
  created and the same scripts are at `<repo>/.agents/skills/flow-trail/scripts/`.

## The manifest

`.claude-plugin/` holds the Claude Code plugin manifest and nothing else. Delete it and the rest
still works; the installer above does not look at it. It is also the only file that carries a
version, which is what an upgrade is checked against.

- `npx skills add benxgao/flow-trail -g` is the older route, tested end to end on Claude Code.
- It writes `~/.agents/skills/` and `~/.claude/skills/` only, so run the installer after it.
- That route owns its copy afterwards: `npx skills update flow-trail` moves it. Two owners, one
  upgrade: [upgrade.md](upgrade.md).
