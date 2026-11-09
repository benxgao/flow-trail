#!/usr/bin/env bash
# Session-start context for flow-trail.
#
#   bash session-start.sh [root]      # default: ./flow-trail
#
# Prints a short plain-text pointer plus every card's `next:` line. A hook
# prints this at session start, so the agent begins already knowing the folder
# exists and where the last session stopped.
#
# Silent when there is no flow-trail/ folder: an unrelated repository must see
# no output at all.

set -uo pipefail

# A harness pipes its event JSON on stdin. Drain it so the writer never blocks.
if [ ! -t 0 ]; then
  cat >/dev/null 2>&1 || true
fi

ROOT="${1:-flow-trail}"
[ -d "$ROOT" ] || exit 0

# Days between a YYYY-MM-DD date and today. Prints nothing when the platform's
# date command refuses; the caller then shows the date without a verdict.
days_since() {
  if ts=$(date -d "$1" +%s 2>/dev/null); then :
  elif ts=$(date -j -f "%Y-%m-%d" "$1" +%s 2>/dev/null); then :
  else return 1; fi
  echo $(( ( $(date +%s) - ts ) / 86400 ))
}

STALE_DAYS="${FLOW_TRAIL_STALE_DAYS:-30}"

echo "flow-trail: work larger than one commit is tracked in $ROOT/ as a board. Read $ROOT/README.md"
echo "before starting. Resume from $ROOT/doing/<card>/progress.md; a skip costs one row in $ROOT/skips.md."

shown=0
while IFS= read -r dir; do
  [ -f "$dir/progress.md" ] || continue
  next=$(grep -m1 '^next:' "$dir/progress.md" 2>/dev/null | sed -e 's/^next:[[:space:]]*//' -e 's/^"//' -e 's/"$//')
  [ -n "$next" ] || next="(no next: line — read the session notes)"
  # Newest session-note heading. The threshold only adds a word; deleting or
  # keeping the card stays the reader's decision.
  last=$(grep -oE '^### [0-9]{4}-[0-9]{2}-[0-9]{2}' "$dir/progress.md" 2>/dev/null | tail -1 | cut -c5-)
  note=""
  if [ -n "$last" ]; then
    note=" [last $last"
    if age=$(days_since "$last") && [ "$age" -ge "$STALE_DAYS" ]; then
      note="$note, stale ${age}d"
    fi
    note="$note]"
  fi
  echo "doing: $dir — $next$note"
  shown=$((shown + 1))
  [ "$shown" -ge 4 ] && break
done < <(find "$ROOT/doing" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

exit 0
