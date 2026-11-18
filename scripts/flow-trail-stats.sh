#!/usr/bin/env bash
# What the board looks like from outside: one row per card, one line of totals.
#
#   bash flow-trail-stats.sh [root]            # the table
#   bash flow-trail-stats.sh --verify [root]   # + re-run every Outcome command (slow)
#   bash flow-trail-stats.sh --brief [root]    # the one line session-start prints
#
# This is the answer to "is any of this being read, and is any of it still true".
# A card nobody cites shows `0/5` in the cited column; a card whose claims have
# rotted shows a drift count under --verify. Nothing is written, and only
# --verify executes anything.

set -uo pipefail

ROOT="flow-trail"
BRIEF=0
VERIFY=0
for arg in "$@"; do
  case "$arg" in
    --brief) BRIEF=1 ;;
    --verify) VERIFY=1 ;;
    *) ROOT="$arg" ;;
  esac
done

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

[ -d "$ROOT" ] || { printf 'no %s/ here — nothing to report\n' "$ROOT"; exit 0; }

# The three most recently closed cards, for the session-start hook.
recent_done() {
  ls -dt "$ROOT"/done/*/ 2>/dev/null | head -3 | while IFS= read -r d; do basename "$d"; done | paste -sd, - | sed 's/,/, /g'
}

if [ "$BRIEF" -eq 1 ]; then
  names=$(recent_done)
  [ -n "$names" ] && echo "done: $names — closed cards; open one before re-deciding in its area"
  exit 0
fi

# rows / strict / manual, read off the Outcome table the same way verify does.
row_counts() {
  awk '
    /^## Outcome/ { inb = 1; next }
    /^## /        { inb = 0 }
    inb && /^\|/ {
      n = split($0, a, "|")
      if (n < 6) next
      metric = a[2]; verify = ""
      if (n >= 7) verify = a[6]
      gsub(/^[ \t]+|[ \t]+$/, "", metric)
      gsub(/^[ \t]+|[ \t]+$/, "", verify)
      gsub("`", "", verify)
      if (metric == "Metric" || metric ~ /^[-: ]+$/) next
      rows++
      if (verify ~ /^manual/) manual++
      else if (verify != "" && verify != "-" && verify !~ /^</) strict++
    }
    END { printf "%d %d %d", rows, strict, manual }
  ' "$1" 2>/dev/null
}

closed_on() {
  # Absolute, because -C changes the directory the relative path was written for.
  local abs
  abs=$(cd "$1" && pwd)
  git -C "$(dirname "$ROOT")" log -1 --format=%cs -- "$abs" 2>/dev/null || true
}

if [ "$VERIFY" -eq 1 ] && [ -x "$SCRIPT_DIR/verify-outcome.sh" ]; then
  vbuf=$(bash "$SCRIPT_DIR/verify-outcome.sh" --run "$ROOT" 2>&1)
fi

if [ "$VERIFY" -eq 1 ]; then
  printf '%-26s %-6s %-10s %5s %7s %5s %6s %7s %7s %6s\n' \
    card column edited finds cited rows strict manual verify lines
  printf '%-26s %-6s %-10s %5s %7s %5s %6s %7s %7s %6s\n' \
    ------------------------ ------ ---------- ----- ----- ----- ------ ------- ------- ------
else
  printf '%-26s %-6s %-10s %5s %7s %5s %6s %7s %6s\n' \
    card column edited finds cited rows strict manual lines
  printf '%-26s %-6s %-10s %5s %7s %5s %6s %7s %6s\n' \
    ------------------------ ------ ---------- ----- ----- ----- ------ ------- ------
fi

t_finds=0 t_cited=0 t_rows=0 t_strict=0 t_manual=0 t_cards=0 t_doing=0

for column in doing done backlog; do
  for dir in "$ROOT/$column"/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    t_cards=$((t_cards + 1))
    [ "$column" = "doing" ] && t_doing=$((t_doing + 1))

    f="$dir/findings.md"
    if [ -f "$f" ]; then
      finds=$(grep -cE '^## F[0-9]+ — ' "$f" || true)
      cites=$(grep -c '\*\*Cited by\*\*' "$f" || true)
      uncited=$(grep '\*\*Cited by\*\*' "$f" | grep -c 'nothing yet' || true)
      cited=$((cites - uncited))
      lines=$(wc -l < "$f" | tr -d ' ')
    else
      finds=0; cited=0; lines=0
    fi

    set -- $(row_counts "$dir/README.md" 2>/dev/null)
    rows=${1:-0}; strict=${2:-0}; manual=${3:-0}

    closed=$(closed_on "$dir")
    [ -n "$closed" ] || closed="-"

    t_finds=$((t_finds + finds))
    t_cited=$((t_cited + cited))
    t_rows=$((t_rows + rows))
    t_strict=$((t_strict + strict))
    t_manual=$((t_manual + manual))

    if [ "$VERIFY" -eq 1 ]; then
      if [ -n "${vbuf:-}" ]; then
        ok=$(printf '%s\n' "$vbuf" | awk -v l="$name" '$1 == "ok" && $2 == l' | wc -l | tr -d ' ')
        bad=$(printf '%s\n' "$vbuf" | awk -v l="$name" '($1 == "DRIFT" || $1 == "FAIL") && $2 == l' |
          wc -l | tr -d ' ')
        verdict="$ok/$bad"
      else
        verdict="-"
      fi
      printf '%-26s %-6s %-10s %5s %7s %5s %6s %7s %7s %6s\n' \
        "$name" "$column" "$closed" "$finds" "$cited/$finds" "$rows" "$strict" "$manual" \
        "$verdict" "$lines"
    else
      printf '%-26s %-6s %-10s %5s %7s %5s %6s %7s %6s\n' \
        "$name" "$column" "$closed" "$finds" "$cited/$finds" "$rows" "$strict" "$manual" "$lines"
    fi
  done
done

if [ "$t_cards" -eq 0 ]; then
  printf '\nno cards yet. A card appears in %s/doing/ when work starts.\n' "$ROOT"
  exit 0
fi

printf '\n%d card(s): %d doing, %d closed. %d finding(s), %d cited; %d Outcome row(s), ' \
  "$t_cards" "$t_doing" "$((t_cards - t_doing))" "$t_finds" "$t_cited" "$t_rows"
printf '%d with a Verify assertion, %d manual.\n' "$t_strict" "$t_manual"

if [ "$VERIFY" -ne 1 ]; then
  printf 'Run with --verify to execute the Outcome commands (that column is ok/drift).\n'
fi
