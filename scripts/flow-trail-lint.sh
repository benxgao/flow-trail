#!/usr/bin/env bash
# flow-trail lint — ten checks over a flow-trail/ root.
#
#   bash flow-trail-lint.sh [root]      # default: flow-trail
#
# It reports; it gates nothing. Exit 0 when no errors.
# Every rule here is a grep or a test -f. A rule that cannot be written as one
# was deleted rather than tooled — see references/design-notes.md.

set -uo pipefail

ROOT="${1:-flow-trail}"
HEADINGS=("## Outcome" "## Contract" "## Decisions" "## Lessons" "## Residual" "## Where the proof lives")
LINE_CAP=120
FINDINGS_CAP=200

errors=0
warnings=0

err() { printf 'error   %s\n' "$*"; errors=$((errors + 1)); }
warn() { printf 'warning %s\n' "$*"; warnings=$((warnings + 1)); }

if [ ! -d "$ROOT" ]; then
  printf '%s/ not found — nothing to check\n' "$ROOT"
  exit 0
fi

# Existing cards carry the six headings; check that one file has all of them.
has_six_headings() {
  local file="$1" missing=""
  for h in "${HEADINGS[@]}"; do
    grep -qF "$h" "$file" || missing="$missing [$h]"
  done
  [ -z "$missing" ] || { printf '%s' "$missing"; return 1; }
  return 0
}

# --- doing: README + progress ----------------------------------------------
while IFS= read -r dir; do
  [ -f "$dir/README.md" ] || err "E1 card in doing has no README.md: $dir"
  [ -f "$dir/progress.md" ] || err "E1 card in doing has no progress.md: $dir"
done < <(find "$ROOT/doing" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

# --- backlog: one page, no state -------------------------------------------
while IFS= read -r dir; do
  [ -f "$dir/README.md" ] || err "E7 card in backlog has no README.md: $dir"
  for stale in progress.md findings.md; do
    [ -e "$dir/$stale" ] && err "E7 card in backlog holds $stale: $dir"
  done
done < <(find "$ROOT/backlog" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

# --- done: README only -----------------------------------------------------
while IFS= read -r dir; do
  [ -f "$dir/README.md" ] || { err "E2 closed card has no README.md: $dir"; continue; }
  [ -f "$dir/progress.md" ] && err "E2 closed card still holds progress.md: $dir"
  for stale in "$dir"/*-rollout.md "$dir"/plan.md; do
    [ -e "$stale" ] && err "E2 closed card still holds $(basename "$stale"): $dir"
  done
  if ! out=$(has_six_headings "$dir/README.md"); then
    err "E3 closed README is missing headings: $dir ->$out"
  fi
  if grep -qE '^[[:space:]]*- \[[ x~v!-]\]' "$dir/README.md"; then
    err "E4 closed README carries a checkbox: $dir"
  fi
  lines=$(wc -l < "$dir/README.md" | tr -d ' ')
  [ "$lines" -gt "$LINE_CAP" ] && warn "W1 closed README is $lines lines (cap $LINE_CAP): $dir"
  if [ -f "$dir/findings.md" ]; then
    grep -qF 'findings.md' "$dir/README.md" ||
      err "E6 closed card has findings.md but its README never links it: $dir"
    flines=$(wc -l < "$dir/findings.md" | tr -d ' ')
    [ "$flines" -gt "$FINDINGS_CAP" ] &&
      warn "W2 findings.md is $flines lines (cap $FINDINGS_CAP): $dir"
  fi
done < <(find "$ROOT/done" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

# --- skips: a skip is a decision and carries four cells ---------------------
if [ -f "$ROOT/skips.md" ]; then
  while IFS= read -r row; do
    cells=$(printf '%s' "$row" | awk -F'|' '{print NF-2}')
    [ "$cells" -lt 4 ] && err "E5 skip row has $cells cells, needs 4: $row"
  done < <(grep -E '^\|[^|]+\|' "$ROOT/skips.md" | grep -vE '^\|[[:space:]]*-+' | grep -vF '| Date |')
fi

# --- one card in flight -----------------------------------------------------
doing=$(find "$ROOT/doing" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
[ "$doing" -gt 1 ] && warn "W3 doing holds $doing cards; one at a time, say which is current"

printf '\n%d error, %d warning\n' "$errors" "$warnings"
[ "$errors" -eq 0 ]
