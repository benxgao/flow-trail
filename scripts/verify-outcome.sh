#!/usr/bin/env bash
# Re-runs the commands recorded in each card's `## Outcome` table — `done/` and
# `doing/`, so a number written before it was measured is caught while it is still
# a plan rather than after the card closes.
#
#   bash verify-outcome.sh [root]          # dry run: list what would be run
#   bash verify-outcome.sh --run [root]    # actually execute the commands
#
# A row can say three things:
#
#   Verify cell present  -> an assertion. Exit 0 is `ok`; anything else is `DRIFT`.
#   Verify cell absent   -> `LOOSE`: the recorded After text must appear in the
#                           output of the Command. A LOOSE row in prose always
#                           reads as a mismatch, so LOOSE never fails the run.
#   After says `planned` -> `plan` in `doing/` (nothing to verify yet), `DRIFT` in
#                           `done/` (a closed card may not hold an unmeasured number).
#
# Exit 1 only for a strict DRIFT or a command failure. A checker that goes all red
# on a healthy card teaches people to ignore it, which is worse than no checker.
#
# It executes commands written in your own repository, which is why they only run
# with --run. Nothing is modified.

set -uo pipefail

RUN=0
ROOT="flow-trail"
for arg in "$@"; do
  case "$arg" in
    --run) RUN=1 ;;
    *) ROOT="$arg" ;;
  esac
done

[ -d "$ROOT/done" ] || [ -d "$ROOT/doing" ] ||
  { printf 'no %s/done/ or %s/doing/ here — nothing to verify\n' "$ROOT" "$ROOT"; exit 0; }

# The recorded commands were written for the project root, not for wherever the
# reader happens to stand. `dirname flow-trail` is "." when run from the root.
PROJ=$(cd "$(dirname "$ROOT")" && pwd)

checked=0
okcount=0
loose=0
planned=0
drift=0
driftcmd=0

while IFS= read -r track; do
  label=$(basename "$track")
  col=$(basename "$(dirname "$track")")
  # A cell writes a literal pipe as `\|`, because a bare one ends the column. The
  # command must run with a real pipe, so the escape is decoded before the split —
  # otherwise a pipeline inside a cell is cut into pieces and shoved into the next
  # column, and the assertion fails on a card that is perfectly healthy.
  # A fifth cell is still rebuilt from the remaining fields, for a pipe written raw.
  rows=$(awk '
    /^## Outcome/ { inb = 1; next }
    /^## /        { inb = 0 }
    inb && /^\|/ {
      line = $0
      gsub(/\\\|/, "\001", line)
      n = split(line, a, "|")
      if (n < 6) next
      metric = a[2]; after = a[4]; cmd = a[5]; verify = ""
      if (n >= 7) {
        verify = a[6]
        for (i = 7; i < n; i++) verify = verify "|" a[i]
      }
      gsub(/\001/, "|", metric)
      gsub(/\001/, "|", after)
      gsub(/\001/, "|", cmd)
      gsub(/\001/, "|", verify)
      gsub(/^[ \t]+|[ \t]+$/, "", metric)
      gsub(/^[ \t]+|[ \t]+$/, "", after)
      gsub(/^[ \t]+|[ \t]+$/, "", cmd)
      gsub(/^[ \t]+|[ \t]+$/, "", verify)
      gsub(/`/, "", cmd)
      gsub(/`/, "", after)
      gsub(/`/, "", verify)
      if (metric == "Metric" || metric ~ /^[-: ]+$/ || cmd == "") next
      print metric "\t" after "\t" cmd "\t" verify
    }
  ' "$track/README.md" 2>/dev/null)

  [ -n "$rows" ] || continue

  while IFS=$'\t' read -r metric after cmd verify; do
    checked=$((checked + 1))

    # The template asks for `planned` in the After cell of a number nobody has
    # measured yet. Open, that is honest; closed, it is the one thing a closed card
    # may not be, so it counts against the run.
    case "$after" in
      *planned*)
        if [ "$col" = "done" ]; then
          printf 'DRIFT %-12s %-22s closed with an unmeasured number: %s\n' \
            "$label" "$metric" "$after"
          drift=$((drift + 1))
        else
          printf 'plan  %-12s %-22s %s\n' "$label" "$metric" "$after"
          planned=$((planned + 1))
        fi
        continue ;;
    esac

    # A leftover template placeholder is not an assertion; `manual` says a person
    # must run it (a deployed stage, a secret) and is never counted as drift.
    case "$verify" in
      "" | "-" | "<"*">") has_verify=0 ;;
      manual*) has_verify=2 ;;
      *) has_verify=1 ;;
    esac

    if [ "$has_verify" -eq 2 ]; then
      reason="${verify#manual}"
      reason="${reason#: }"
      printf 'skip  %-12s %-22s (manual%s)\n' "$label" "$metric" "${reason:+, $reason}"
      continue
    fi

    if [ "$has_verify" -eq 0 ] && { [ -z "$after" ] || [ "$after" = "-" ]; }; then
      printf 'skip  %-12s %-22s (no after value recorded)\n' "$label" "$metric"
      continue
    fi

    if [ "$RUN" -eq 0 ]; then
      if [ "$has_verify" -eq 1 ]; then
        printf 'strict %-12s %-22s %s\n' "$label" "$metric" "$verify"
      else
        printf 'loose  %-12s %-22s %s\n' "$label" "$metric" "$cmd"
      fi
      continue
    fi

    if [ "$has_verify" -eq 1 ]; then
      if (cd "$PROJ" && bash -c "$verify") >/dev/null 2>&1; then
        printf 'ok    %-12s %-22s %s\n' "$label" "$metric" "$verify"
        okcount=$((okcount + 1))
      else
        printf 'DRIFT %-12s %-22s assertion failed: %s\n' "$label" "$metric" "$verify"
        drift=$((drift + 1))
      fi
      continue
    fi

    out=$(cd "$PROJ" && bash -c "$cmd" 2>&1)
    status=$?
    if [ "$status" -ne 0 ]; then
      printf 'FAIL  %-12s %-22s %s -> exit %d\n' "$label" "$metric" "$cmd" "$status"
      drift=$((drift + 1)); driftcmd=$((driftcmd + 1))
    elif printf '%s' "$out" | grep -qF -- "$after"; then
      printf 'ok?   %-12s %-22s %s (loose: text found)\n' "$label" "$metric" "$cmd"
      okcount=$((okcount + 1)); loose=$((loose + 1))
    else
      printf 'LOOSE %-12s %-22s recorded "%s" not in the output — add a Verify assertion\n' \
        "$label" "$metric" "$after"
      loose=$((loose + 1))
    fi
  done <<< "$rows"
done < <(find "$ROOT/done" "$ROOT/doing" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

if [ "$checked" -eq 0 ]; then
  printf 'no Outcome rows with a command yet\n'
  exit 0
fi

if [ "$RUN" -eq 0 ]; then
  printf '\n%d rows. Re-run with --run to execute them.\n' "$checked"
  exit 0
fi

printf '\n%d rows: %d ok, %d loose, %d planned, %d drifted, %d command failures\n' \
  "$checked" "$okcount" "$loose" "$planned" "$drift" "$driftcmd"
[ "$loose" -gt 0 ] &&
  printf 'loose rows are not a verdict: give them a Verify assertion to make them one\n'
[ "$drift" -eq 0 ]
