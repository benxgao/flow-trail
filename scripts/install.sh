#!/usr/bin/env bash
# One command that makes the board work in a repository, and the one that upgrades it.
#
#   bash <this-skill>/scripts/install.sh [--dry-run] [--relink] [project-dir]
#
# Four steps, each skipped when it is already done:
#   1. Link this skill into every harness skills folder the machine has.
#   2. Append the pointer to AGENTS.md, and to CLAUDE.md / GEMINI.md when they exist.
#   3. Keep the skill's own source out of git, via .gitignore.
#   4. Create flow-trail/README.md, skips.md and usage.md.
#
# Idempotent: a second run reports the same state and writes nothing.
# A folder where a link should be is left alone unless --relink is given. That
# replaces an older copy, and it is the only step here that deletes anything.

set -uo pipefail

DRY=0
RELINK=0
ROOT="$PWD"

usage() {
  awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$0"
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --relink|--replace) RELINK=1 ;;
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

# The manifest is the only file that carries a version. An upgrade a user cannot
# name is an upgrade they cannot tell from a no-op, so both sides are printed.
skill_version() {
  local v
  v=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$1/.claude-plugin/plugin.json" 2>/dev/null | head -1)
  printf '%s' "${v:-unknown}"
}
# Reads as a noun in every sentence below: "a 0.1.2 copy", "a copy with no manifest".
copy_label() {
  if [ "$1" = "unknown" ]; then printf 'copy with no manifest'; else printf '%s copy' "$1"; fi
}
VERSION=$(skill_version "$SKILL_DIR")

REPORT_LINKED=()
REPORT_SKIPPED=()
REPORT_PROJECT=()
REPORT_CARDS=()

# A harness that is installed gets a link; one that is not, does not.
link_skill() {
  local dir="$1" dest="$1/flow-trail" old label
  if [ ! -d "$dir" ]; then
    [ "$DRY" -eq 1 ] && REPORT_LINKED+=("$dir (would create and link)")
    return 0
  fi
  if [ -L "$dest" ] && [ "$(cd "$dest" 2>/dev/null && pwd -P)" = "$SKILL_DIR" ]; then
    REPORT_SKIPPED+=("$dir (already linked)")
    return 0
  fi
  # Running --relink from inside the folder it would replace deletes the script mid-run.
  if [ -e "$dest" ] && [ "$(cd "$dest" 2>/dev/null && pwd -P)" = "$SKILL_DIR" ]; then
    REPORT_SKIPPED+=("$dir (this checkout: nothing to replace)")
    return 0
  fi
  if [ -e "$dest" ]; then
    old=$(skill_version "$dest")
    # A link and a copy fail differently, and an upgrade that names neither is the bug.
    if [ -L "$dest" ]; then
      label="link to $(cd "$dest" 2>/dev/null && pwd -P)"
    else
      label=$(copy_label "$old")
    fi
    # --relink replaces what is there only when it is this skill. Anything else stays.
    if [ "$RELINK" -eq 1 ] && grep -qE '^name:[[:space:]]*flow-trail[[:space:]]*$' \
      "$dest/SKILL.md" 2>/dev/null; then
      if [ "$DRY" -eq 1 ]; then
        REPORT_LINKED+=("$dir (would replace a $label with a link to $VERSION)")
        return 0
      fi
      rm -rf "$dest" && ln -s "$SKILL_DIR" "$dest" &&
        REPORT_LINKED+=("$dir (replaced a $label with a link to $VERSION)")
      return 0
    fi
    REPORT_SKIPPED+=("$dir (a $label, left alone; --relink replaces it with a link to $VERSION)")
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

# A project-level copy is the other owner. `npx skills add` writes one and records it
# in skills-lock.json; step 1 does not reach it, and a harness that reads both folders
# prefers the copy. Say which version it is, because nothing else will.
for pdir in "$ROOT/.agents/skills" "$ROOT/.claude/skills"; do
  pdest="$pdir/flow-trail"
  [ -e "$pdest" ] || continue
  if [ -L "$pdest" ]; then
    [ "$(cd "$pdest" 2>/dev/null && pwd -P)" = "$SKILL_DIR" ] ||
      REPORT_PROJECT+=("${pdest#$ROOT/} (link to another checkout, not $SKILL_DIR)")
    continue
  fi
  pv=$(skill_version "$pdest")
  [ "$pv" = "$VERSION" ] && continue
  if [ -f "$ROOT/skills-lock.json" ]; then
    REPORT_PROJECT+=("${pdest#$ROOT/} (a $(copy_label "$pv"); npx skills update flow-trail upgrades it)")
  else
    REPORT_PROJECT+=("${pdest#$ROOT/} (a $(copy_label "$pv"); rm -r it, then re-run with --relink)")
  fi
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
| `usage.md` | Later tasks that actually used a finding | forever |

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

# A folder note written by an older release still reads fine until a reader looks for
# the file it does not list. Replacing it would throw the user's edits away, so the
# report says which row is missing instead.
if [ "$README_STATE" = "already there" ] &&
   ! grep -q '`usage.md`' "$ROOT/flow-trail/README.md" 2>/dev/null; then
  README_STATE="older template: no usage.md row — delete the file and re-run"
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
USAGE_STATE="already there"
if [ ! -f "$ROOT/flow-trail/usage.md" ] && [ -x "$SKILL_DIR/scripts/flow-trail-usage.sh" ]; then
  if [ "$DRY" -eq 1 ]; then
    USAGE_STATE="would create"
  else
    bash "$SKILL_DIR/scripts/flow-trail-usage.sh" --init "$ROOT/flow-trail" >/dev/null && USAGE_STATE="added"
  fi
fi
BOARD_STATE="README.md ($README_STATE), skips.md ($SKIPS_STATE), usage.md ($USAGE_STATE)"

# The cards belong to the user, and each keeps the shape of the release that wrote it.
# Name the release, not the rule: the linter can only say E13, and a code is not a fix.
for card in "$ROOT"/flow-trail/*/*/findings.md; do
  [ -f "$card" ] || continue
  cname=$(basename "$(dirname "$card")")
  if grep -qE '^## Measurements' "$card" 2>/dev/null; then
    REPORT_CARDS+=("$cname (predates 0.2.1: '## Measurements' is '## Receipts' now)")
    continue
  fi
  nf=$(grep -cE '^## F[0-9]+ — ' "$card" || true)
  [ "$nf" -gt 0 ] || continue
  nwhy=$(grep -c '\*\*Not in the code because\*\*' "$card" || true)
  nrot=$(grep -cE '^- \*\*(Check|Dies when)\*\*' "$card" || true)
  if [ "$nwhy" -lt "$nf" ] || [ "$nrot" -lt "$nf" ]; then
    REPORT_CARDS+=("$cname (predates 0.4.0: $nwhy of $nf finding(s) have 'Not in the code because')")
  fi
done

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

printf '\nflow-trail %s install%s\n\n' "$VERSION" \
  "$([ "$DRY" -eq 1 ] && printf ' (dry run, nothing written)' || true)"
print_list skill "$SKILL_DIR ($VERSION)"
print_list linked ${REPORT_LINKED[@]+"${REPORT_LINKED[@]}"}
print_list skipped ${REPORT_SKIPPED[@]+"${REPORT_SKIPPED[@]}"}
[ "${#REPORT_PROJECT[@]}" -gt 0 ] && print_list project ${REPORT_PROJECT[@]+"${REPORT_PROJECT[@]}"}
print_list pointer ${POINTER_STATE[@]+"${POINTER_STATE[@]}"}
print_list gitignore ${IGNORE_STATE[@]+"${IGNORE_STATE[@]}"}
print_list board "flow-trail/$BOARD_STATE"
[ "${#REPORT_CARDS[@]}" -gt 0 ] && print_list cards ${REPORT_CARDS[@]+"${REPORT_CARDS[@]}"}
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
