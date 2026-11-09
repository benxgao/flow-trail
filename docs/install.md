# Install, per harness

One command, then the routes for a harness that does not take it.

```bash
npx skills add benxgao/flow-trail -g
```

- Installs for the current user, in the skills folder the harness already reads.
- Nothing else to configure: the first card creates the folders it needs.

## Two folders cover most harnesses

- `~/.agents/skills/` is read by Codex, Gemini CLI and DeepSeek Harness.
- `~/.claude/skills/` is read by Claude Code and GitHub Copilot CLI.
- Link the clone into both, and most of the sections below become unnecessary.

```bash
git clone https://github.com/benxgao/flow-trail ~/src/flow-trail
mkdir -p ~/.agents/skills ~/.claude/skills
ln -s ~/src/flow-trail ~/.agents/skills/flow-trail
ln -s ~/src/flow-trail ~/.claude/skills/flow-trail
```

- Per project instead: the same link at `.agents/skills/flow-trail` or `.claude/skills/`.
- `git pull` in the clone updates every harness at once.

## Claude Code

```bash
/plugin marketplace add benxgao/flow-trail
/plugin install flow-trail@flow-trail
```

- `npx skills add` works here too, into `~/.claude/skills/`. Take one route, not both.
- Hook: `.claude/settings.json`, matcher `startup|resume|clear|compact` — [hooks.md](hooks.md).
- It reads `CLAUDE.md` at startup and not `AGENTS.md`: symlink one at the other.

## Codex

- Loads `~/.agents/skills/` per user and `.agents/skills/` per project.
- `~/.codex/skills/` still loads; it is the older location, and `$skill-installer` writes there.
- `/skills` lists what it found; `$flow-trail` calls it by name.
- `AGENTS.md` at the repository root is read every session: copy the pointer from
  [the example](../examples/login-refactor/AGENTS.md).

## GitHub Copilot CLI

- Skills: `.github/skills/flow-trail/SKILL.md` per project, or `~/.copilot/skills/`.
- It reads `.claude/skills/` in both places too, so the link above is enough.
- `/skills list` shows it, `/flow-trail` calls it, `/skills reload` after adding one.
- Copilot Agent reads `AGENTS.md` as custom instructions, with no alias.

## Gemini CLI

- User: `~/.gemini/skills/` or its alias `~/.agents/skills/`, where the link above lands.
- Project: `.gemini/skills/` or `.agents/skills/`; workspace skills need a trusted folder.
- `/skills list`, `/skills reload`. Or let it fetch: `gemini skills install <repo url>`.
- It reads `GEMINI.md`, not `AGENTS.md`: point that file at the pointer if you keep no hook.

## Cursor, Windsurf, Roo Code, Qoder, Trae

- All five read `AGENTS.md` at the repository root. There is nothing to install.
- Copy the pointer from [the example](../examples/login-refactor/AGENTS.md) and it fires.
- Trae desktop ships the switch off: turn on the AGENTS.md option in its rules settings.
- Qoder also reads `AGENTS.local.md`, for rules you keep out of git.

## Cline, and a harness with only its own rules file

- Cline reads `.clinerules`. Make it the same file: `ln -s AGENTS.md .clinerules`.
- Any other rules filename takes the same link, so one file stays the only copy.
- The pointer names `flow-trail/` and the three columns; the skill does the rest.

## Aider

- `~/.aider.conf.yml`, or per project `.aider.conf.yml`:

```yaml
read: AGENTS.md
```

- Aider has no skills folder. The pointer plus the card files is the whole integration.

## WorkBuddy / CodeBuddy

- Skills: `~/.workbuddy-ai/skills/flow-trail/`, or `npx skills add ... -g`.
- Hook file: `~/.workbuddy/settings.json`; per project, `.workbuddy/settings.json`.
- The JSON for both is in [hooks.md](hooks.md).
- Desktop app and CLI do not always read the same settings file.

## DeepSeek Harness

- Four places, earlier wins: `.dsh/skills/`, `.agents/skills/`, `~/.dsh/skills/`,
  `~/.agents/skills/`.
- Scan depth is one folder: `skills/flow-trail/SKILL.md` is found, a nested copy is not.
- The `~/.agents/skills/` link above covers it; `~/.dsh/skills/flow-trail` works the same.
- Restart the session after adding one; `/flow-trail` calls it by hand.

## Optional: the hook

Prints each `next:` line before the first message of a session: [hooks.md](hooks.md).

- Without it, the skill fires when you say "plan this". The pointer is read only if the agent looks.

## Optional: the two scripts

```bash
bash scripts/flow-trail-lint.sh flow-trail   # card shape, ten checks
bash scripts/verify-outcome.sh --run         # re-run every closed card's Outcome commands
```

- Both report and exit 1. Neither gates a commit, and no part of the skill calls them.

## The manifest

`.claude-plugin/` holds the plugin manifest and nothing else. Delete it and the rest still works.
