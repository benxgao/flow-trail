# Make it automatic

- The skill fires only when the agent reads it.
- A session-start hook is what makes it read.
- The harness runs one command, its stdout becomes context.
- That happens before you type anything.

Three lines of output are enough to change behaviour:

```
flow-trail: work larger than one commit is tracked in flow-trail/ as a board. Read flow-trail/README.md
before starting. Resume from flow-trail/doing/<card>/progress.md; a skip costs one row in flow-trail/skips.md.
doing: flow-trail/doing/jwt-policy — P2 — run npm test, then close [last 2026-11-07]
```

- `scripts/session-start.sh` prints exactly that.
- It prints nothing in a project without a `flow-trail/` folder: no noise elsewhere.

Test it before wiring anything:

```bash
bash ~/.claude/skills/flow-trail/scripts/session-start.sh   # run inside a project
```

## Claude Code

`.claude/settings.json` for one project, `~/.claude/settings.json` for every project:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOME/.claude/skills/flow-trail/scripts/session-start.sh\""
          }
        ]
      }
    ]
  }
}
```

- Keep `compact` in the matcher.
- Without it, a long session forgets again after the context window is compressed.
- Hooks are cached at session start: quit the client fully, closing the window is not enough.

## WorkBuddy / CodeBuddy

Same shape, different file.
- Global: `~/.workbuddy/settings.json`. Per project: `.workbuddy/settings.json`.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOME/.workbuddy-ai/skills/flow-trail/scripts/session-start.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

- If nothing fires, check which settings file your build reads.
- Desktop app and CLI do not always agree, and a hook in the wrong file fails silently.

## Any other harness

Two requirements, no more:

- It can run a shell command at session start.
- It treats that command's stdout as context.

No path resolution? This one-liner needs no paths at all:

```bash
sh -c 'test -d flow-trail && echo "flow-trail: multi-session work lives in flow-trail/ as a board. Read flow-trail/README.md before starting; a skip needs one row in flow-trail/skips.md. $(grep -h "^next:" flow-trail/doing/*/progress.md 2>/dev/null | head -3)"; true'
```

## No hooks at all

- Then the pointer in `AGENTS.md` or `CLAUDE.md` is the whole mechanism.
- The skill fires when you say "plan this". It is the fallback, not the design.

## Why not put this inside the skill

- A skill loads when the harness decides it is relevant.
- Deciding that requires knowing the folder exists.
- On the first message of a new session, the agent does not know.
- The hook breaks that circle.
