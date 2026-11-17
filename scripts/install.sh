#!/usr/bin/env bash
# One command that makes the board work in a repository.
#
#   bash <this-skill>/scripts/install.sh [--dry-run] [project-dir]
#
# Four steps, each skipped when it is already done:
#   1. Link this skill into every harness skills folder the machine has.
#   2. Append the pointer to AGENTS.md, and to CLAUDE.md / GEMINI.md when they exist.
#   3. Keep the skill's own source out of git, via .gitignore.
#   4. Create flow-trail/README.md and flow-trail/skips.md.
#
# Idempotent: a second run reports the same state and writes nothing.

set -uo pipefail

DRY=0
ROOT="$PWD"

usage() {
  sed -n '2,13p' "$0" | sed -e 's/^# \{0,1\}//'
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'unknown flag: %s\n' "$arg" >&2; exit 2 ;;
    *) ROOT="$arg" ;;
  esac
done

ROOT=$(cd "$ROOT" 2>/dev/null && pwd -P) || {
  printf 'no such directory: %s\n' "$ROOT" >&2
  exit 2
}
SKILL_DIR=$(cd "$(dirname "$0")/.." && pwd -P)
[ -f "$SKILL_DIR/SKILL.md" ] || { printf 'not a flow-trail checkout: %s\n' "$SKILL_DIR" >&2; exit 2; }

REPORT_LINKED=()
REPORT_SKIPPED=()

# A harness that is installed gets a link; one that is not, does not.
link_skill() {
  local dir="$1" dest="$1/flow-trail"
  if [ ! -d "$dir" ]; then
    [ "$DRY" -eq 1 ] && REPORT_LINKED+=("$dir (would create and link)")
    return 0
  fi
  if [ -L "$dest" ] && [ "$(cd "$dest" 2>/dev/null && pwd -P)" = "$SKILL_DIR" ]; then
    REPORT_SKIPPED+=("$dir (already linked)")
    return 0
  fi
  if [ -e "$dest" ]; then
    REPORT_SKIPPED+=("$dir (another copy; rm -r $dest to relink here)")
    return 0
  fi
  if [ "$DRY" -eq 1 ]; then
    REPORT_LINKED+=("$dir (would link)")
    return 0
  fi
  if ln -s "$SKILL_DIR" "$dest" 2>/dev/null; then
    REPORT_LINKED+=("$dir")
  else
    REPORT_SKIPPED+=("$dir (could not write, check permissions)")
  fi
}

POINTER='## Work tracking

Work larger than one commit is tracked in `flow-trail/` as a board: `backlog/`, `doing/`, `done/`.
Read `flow-trail/README.md` first.
Resume a card from `flow-trail/doing/<card>/progress.md`.
Deciding not to track a change is also a decision: one line in `flow-trail/skips.md`.'

POINTER_STATE=()

add_pointer() {
  local f="$ROOT/$1"
  if [ -f "$f" ] && grep -q 'flow-trail/README.md' "$f" 2>/dev/null; then
    POINTER_STATE+=("$1 (already there)")
    return 0
  fi
  if [ "$DRY" -eq 1 ]; then
    POINTER_STATE+=("$1 (would append)")
    return 0
  fi
  if [ -s "$f" ]; then printf '\n' >> "$f"; fi
  printf '%s\n' "$POINTER" >> "$f"
  POINTER_STATE+=("$1 (added)")
}

# 1. Links. ~/.agents/skills is the neutral folder; the rest only if the app is here.
if [ ! -d "$HOME/.agents/skills" ] && [ "$DRY" -eq 0 ]; then
  mkdir -p "$HOME/.agents/skills"
fi
link_skill "$HOME/.agents/skills"
for app in .claude .codex .copilot .gemini .dsh .workbuddy-ai .codebuddy; do
  [ -d "$HOME/$app" ] || continue
  [ "$DRY" -eq 0 ] && mkdir -p "$HOME/$app/skills"
  link_skill "$HOME/$app/skills"
done

# 2. Pointer. AGENTS.md is read by most harnesses; the other two only if the repo has them.
add_pointer AGENTS.md
for f in CLAUDE.md GEMINI.md; do
  [ -f "$ROOT/$f" ] && add_pointer "$f"
done

# 3. The skill's source is a dependency, not this project's code.
IGNORE_STATE=("no git repository here")
TRACKED_WARN=""
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  IGNORE_STATE=()
  IGNORE_PATHS=(".agents/skills")
  [ -d "$ROOT/.claude/skills" ] && IGNORE_PATHS+=(".claude/skills")
  for p in "${IGNORE_PATHS[@]}"; do
    if git -C "$ROOT" check-ignore -q "$p/" 2>/dev/null; then
      IGNORE_STATE+=("$p/ (already ignored)")
      continue
    fi
    if [ "$DRY" -eq 1 ]; then
      IGNORE_STATE+=("$p/ (would add)")
      continue
    fi
    if ! grep -qs 'Skill installs' "$ROOT/.gitignore" 2>/dev/null; then
      [ -s "$ROOT/.gitignore" ] && printf '\n' >> "$ROOT/.gitignore"
      printf '# Skill installs, if a tool puts one here. Its source is not this project'\''s code.\n' \
        >> "$ROOT/.gitignore"
    fi
    printf '%s/\n' "$p" >> "$ROOT/.gitignore"
    IGNORE_STATE+=("$p/ (added)")
  done
  if git -C "$ROOT" ls-files --error-unmatch .agents/skills >/dev/null 2>&1; then
    TRACKED_WARN=".agents/skills is committed. Untrack it: git rm -r --cached .agents/skills"
  fi
fi

# 4. The board. No lane directories: a lane appears the first time a card needs it.
BOARD_STATE=""
[ "$DRY" -eq 0 ] && mkdir -p "$ROOT/flow-trail" 2>/dev/null
README_STATE="already there"
if [ ! -f "$ROOT/flow-trail/README.md" ]; then
  if [ "$DRY" -eq 1 ]; then
    README_STATE="would create"
  else
    cat > "$ROOT/flow-trail/README.md" <<'BOARD'
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
BOARD
    README_STATE="added"
  fi
fi

SKIPS_STATE="already there"
if [ ! -f "$ROOT/flow-trail/skips.md" ]; then
  if [ "$DRY" -eq 1 ]; then
    SKIPS_STATE="would create"
  else
    printf '| Date | Change | Measured before | Why no folder |\n| --- | --- | --- | --- |\n' \
      > "$ROOT/flow-trail/skips.md"
    SKIPS_STATE="added"
  fi
fi
BOARD_STATE="README.md ($README_STATE), skips.md ($SKIPS_STATE)"

# Report. The last line is the only thing a person has to act on.
# Arrays are expanded through an empty-safe idiom: bash 3.2 is set -u strict.
print_list() {
  local label="$1" first=1 item
  shift
  if [ "$#" -eq 0 ]; then
    printf '  %-10s %s\n' "$label" "none"
    return 0
  fi
  for item in "$@"; do
    if [ "$first" -eq 1 ]; then
      printf '  %-10s %s\n' "$label" "$item"
      first=0
    else
      printf '  %-10s %s\n' "" "$item"
    fi
  done
}

printf '\nflow-trail install%s\n\n' "$([ "$DRY" -eq 1 ] && printf ' (dry run, nothing written)' || true)"
print_list skill "$SKILL_DIR"
print_list linked ${REPORT_LINKED[@]+"${REPORT_LINKED[@]}"}
print_list skipped ${REPORT_SKIPPED[@]+"${REPORT_SKIPPED[@]}"}
print_list pointer ${POINTER_STATE[@]+"${POINTER_STATE[@]}"}
print_list gitignore ${IGNORE_STATE[@]+"${IGNORE_STATE[@]}"}
print_list board "flow-trail/$BOARD_STATE"
[ -n "$TRACKED_WARN" ] && print_list warning "$TRACKED_WARN"
# A link into /tmp dies with the folder it points at. Under $HOME is a place the user keeps.
# Both sides are resolved: on macOS /tmp is a link to /private/tmp.
HOME_REAL=$(cd "$HOME" 2>/dev/null && pwd -P)
case "$SKILL_DIR" in
  "$HOME"/*|"$HOME_REAL"/*) ;;
  /tmp/*|/private/tmp/*|/var/folders/*)
    print_list warning "this copy is temporary: the links break when it goes. Clone to ~/.flow-trail."
    ;;
esac
printf '\nNext: open your agent in this repo and say:  plan <what you are about to build>\n'
