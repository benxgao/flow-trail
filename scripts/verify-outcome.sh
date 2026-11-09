#!/usr/bin/env bash
# Re-runs the commands recorded in each closed card's `## Outcome` table and
# reports whether the recorded number still appears in the output.
#
#   bash verify-outcome.sh [root]          # dry run: list what would be run
#   bash verify-outcome.sh --run [root]    # actually execute the commands
#
# It executes commands written in your own repository, which is why they only run
# with --run. Nothing is modified. Exit 1 if a record drifted.

set -uo pipefail

RUN=0
ROOT="flow-trail"
for arg in "$@"; do
  case "$arg" in
    --run) RUN=1 ;;
    *) ROOT="$arg" ;;
  esac
done

[ -d "$ROOT/done" ] || { printf 'no %s/done/ here — nothing to verify\n' "$ROOT"; exit 0; }

checked=0
drift=0
driftcmd=0

while IFS= read -r track; do
  label=$(basename "$track")
  rows=$(awk '
    /^## Outcome/ { inb = 1; next }
    /^## /        { inb = 0 }
    inb && /^\|/ {
      n = split($0, a, "|")
      if (n < 6) next
      metric = a[2]; after = a[4]; cmd = a[5]
      gsub(/^[ \t]+|[ \t]+$/, "", metric)
      gsub(/^[ \t]+|[ \t]+$/, "", after)
      gsub(/^[ \t]+|[ \t]+$/, "", cmd)
      gsub(/`/, "", cmd)
      gsub(/`/, "", after)
      if (metric == "Metric" || metric ~ /^[-: ]+$/ || cmd == "") next
      print metric "\t" after "\t" cmd
    }
  ' "$track/README.md" 2>/dev/null)

  [ -n "$rows" ] || continue

  while IFS=$'\t' read -r metric after cmd; do
    checked=$((checked + 1))
    if [ -z "$after" ] || [ "$after" = "-" ]; then
      printf 'skip  %-12s %-22s (no after value recorded)\n' "$label" "$metric"
      continue
    fi
    if [ "$RUN" -eq 0 ]; then
      printf 'would %-12s %-22s %s\n' "$label" "$metric" "$cmd"
      continue
    fi
    out=$(bash -c "$cmd" 2>&1)
    status=$?
    if [ "$status" -ne 0 ]; then
      printf 'FAIL  %-12s %-22s %s -> exit %d\n' "$label" "$metric" "$cmd" "$status"
      drift=$((drift + 1)); driftcmd=$((driftcmd + 1))
    elif printf '%s' "$out" | grep -qF -- "$after"; then
      printf 'ok    %-12s %-22s %s\n' "$label" "$metric" "$cmd"
    else
      printf 'DRIFT %-12s %-22s recorded "%s", not in the output of %s\n' "$label" "$metric" "$after" "$cmd"
      drift=$((drift + 1))
    fi
  done <<< "$rows"
done < <(find "$ROOT/done" -mindepth 1 -maxdepth 1 -type d | sort)

if [ "$checked" -eq 0 ]; then
  printf 'no Outcome rows with a command yet\n'
  exit 0
fi

if [ "$RUN" -eq 0 ]; then
  printf '\n%d rows. Re-run with --run to execute them.\n' "$checked"
  exit 0
fi

printf '\n%d rows, %d drifted, %d command failures\n' "$checked" "$drift" "$driftcmd"
[ "$drift" -eq 0 ]
