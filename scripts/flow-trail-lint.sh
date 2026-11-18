#!/usr/bin/env bash
# flow-trail lint — fifteen checks over a flow-trail/ root.
#
#   bash flow-trail-lint.sh [root]      # default: flow-trail
#
# It reports; it gates nothing. Exit 0 when no errors.
# Every rule here is a grep or a test -f. A rule that cannot be written as one
# was deleted rather than tooled — see references/design-notes.md.

set -uo pipefail

ROOT="${1:-flow-trail}"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SILENT_DAYS="${FLOW_TRAIL_SILENT_DAYS:-30}"
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

# Findings are findings: F-numbered, each with what it costs and what cites it.
# A section called "Measurements" is a receipt, and receipts belong under ## Receipts.
check_findings() {
  local dir="$1" f="$1/findings.md" bad nf nc ncite
  [ -f "$f" ] || return 0
  bad=$(grep -E '^## ' "$f" | grep -vE '^## F[0-9]+ — |^## Reference|^## Receipts' | head -1)
  [ -z "$bad" ] || err "E8 findings heading is not '## F<n> — ' / Reference / Receipts: $dir -> $bad"
  nf=$(grep -cE '^## F[0-9]+ — ' "$f" || true)
  nc=$(grep -c '\*\*Cost if unknown\*\*' "$f" || true)
  ncite=$(grep -c '\*\*Cited by\*\*' "$f" || true)
  [ "$nc" -eq "$nf" ] || err "E9 $nf finding(s) but $nc 'Cost if unknown' line(s): $dir"
  [ "$ncite" -eq "$nf" ] || err "E9 $nf finding(s) but $ncite 'Cited by' line(s): $dir"
}

# A citation is `path :: string that must still be there`. A line number is not
# checkable: it is false after the next commit above it, and no grep can say
# whether it moved or died. This resolves the needle instead.
check_citations() {
  local dir="$1" f="$1/findings.md" proj target cpath cneedle ref line
  [ -f "$f" ] || return 0
  proj=$(dirname "$ROOT")
  while IFS= read -r line; do
    case "$line" in *'**Cited by**'*) ;; *) continue ;; esac
    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      case "$ref" in
        *nothing\ yet* | *http*) continue ;;
        *' :: '*)
          cpath="${ref%% :: *}"
          cneedle="${ref#* :: }"
          # A bare README.md means this card's own README, not the project's.
          if [ "$cpath" = "README.md" ]; then
            target="$dir/README.md"
          else
            target="$proj/$cpath"
          fi
          if [ ! -f "$target" ]; then
            err "E11 cited file does not exist: $dir -> $cpath"
          elif ! grep -qF -- "$cneedle" "$target"; then
            err "E11 citation rotted: $dir -> $cpath :: $cneedle"
          fi
          ;;
        *:[0-9]*)
          warn "W4 citation carries a line number, which rots: $dir -> $ref" ;;
        */* | *.*)
          # A bare path: the file is all that can be checked without a needle.
          [ -f "$proj/$ref" ] || err "E11 cited file does not exist: $dir -> $ref" ;;
      esac
    done < <(printf '%s\n' "$line" | grep -o '`[^`]*`' | tr -d '`')
  done < "$f"
}

# --- doing: README + progress ----------------------------------------------
while IFS= read -r dir; do
  [ -f "$dir/README.md" ] || err "E1 card in doing has no README.md: $dir"
  [ -f "$dir/progress.md" ] || err "E1 card in doing has no progress.md: $dir"
  check_findings "$dir"
  check_citations "$dir"
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
  check_findings "$dir"
  check_citations "$dir"
  # progress.md is deleted at close, so a pointer to it enforces nothing.
  if grep -q 'progress\.md' "$dir/README.md"; then
    err "E10 closed README points at progress.md, which no longer exists: $dir"
  fi
done < <(find "$ROOT/done" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

# --- skips: a skip is a decision and carries four cells ---------------------
if [ -f "$ROOT/skips.md" ]; then
  while IFS= read -r row; do
    cells=$(printf '%s' "$row" | awk -F'|' '{print NF-2}')
    [ "$cells" -lt 4 ] && err "E5 skip row has $cells cells, needs 4: $row"
  done < <(grep -E '^\|[^|]+\|' "$ROOT/skips.md" | grep -vE '^\|[[:space:]]*-+' | grep -vF '| Date |')
fi

# --- usage: a row is an event only if its ref resolves ----------------------
if [ -f "$ROOT/usage.md" ] && [ -x "$SCRIPT_DIR/flow-trail-usage.sh" ]; then
  while IFS= read -r bad; do
    [ -n "$bad" ] && err "E12 usage $bad"
  done < <(bash "$SCRIPT_DIR/flow-trail-usage.sh" --check "$ROOT" 2>/dev/null)
fi

# Silence is the third state, and after a month it is worth a prompt: a card
# nobody has used may be dead weight, or may be unfindable. The two need
# different fixes, so the warning names the card rather than guessing.
days_since() {
  if ts=$(date -d "$1" +%s 2>/dev/null); then :
  elif ts=$(date -j -f "%Y-%m-%d" "$1" +%s 2>/dev/null); then :
  else return 1; fi
  echo $(( ($(date +%s) - ts) / 86400 ))
}

while IFS= read -r dir; do
  [ -f "$dir/findings.md" ] || continue
  finds=$(grep -cE '^## F[0-9]+ — ' "$dir/findings.md" || true)
  [ "$finds" -gt 0 ] || continue
  name=$(basename "$dir")
  used=0
  [ -f "$ROOT/usage.md" ] && used=$(grep -cE "^\| [0-9-]+ \| $name \|" "$ROOT/usage.md" 2>/dev/null || true)
  [ "$used" -gt 0 ] && continue
  last=$(git -C "$(dirname "$ROOT")" log -1 --format=%cs -- "$dir" 2>/dev/null || true)
  [ -n "$last" ] || continue
  age=$(days_since "$last") || continue
  [ "$age" -ge "$SILENT_DAYS" ] &&
    warn "W5 no usage event in ${age}d, $finds finding(s) unused: $name — dead weight or unfindable?"
done < <(find "$ROOT/done" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

# --- one card in flight -----------------------------------------------------
doing=$(find "$ROOT/doing" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
[ "$doing" -gt 1 ] && warn "W3 doing holds $doing cards; one at a time, say which is current"

printf '\n%d error, %d warning\n' "$errors" "$warnings"
[ "$errors" -eq 0 ]
