#!/usr/bin/env bash
# Records that a closed card's finding was actually used — and checks the record.
#
#   bash flow-trail-usage.sh --add <card> <F#> <applied|falsified> "<what changed>" \
#        --ref commit:<sha>|test:<path>|pr:<n> [--via grep|hook|readme|memory] [root]
#   bash flow-trail-usage.sh --check [root]
#   bash flow-trail-usage.sh --init  [root]
#
# Two kinds, and no third:
#
#   applied     a finding changed what was done — a decision, a test, a path not taken
#   falsified   a finding was no longer true when someone relied on it
#
# Reading a card is not an event: volume without signal. A row whose ref cannot be
# resolved is not an event either: an unverifiable claim is a story. That is the
# whole filter, and it is why the log stays small enough to read.

set -uo pipefail

ROOT="flow-trail"
MODE=""
CARD=""
FINDING=""
KIND=""
NOTE=""
REF=""
VIA="memory"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --add) MODE=add; shift
      CARD="${1:-}"; FINDING="${2:-}"; KIND="${3:-}"; NOTE="${4:-}"
      shift 4 2>/dev/null || shift $# ;;
    --check) MODE=check; shift ;;
    --init) MODE=init; shift ;;
    --ref) REF="${2:-}"; shift 2 ;;
    --via) VIA="${2:-}"; shift 2 ;;
    *) ROOT="$1"; shift ;;
  esac
done

[ -d "$ROOT" ] || { printf 'no %s/ here — nothing to record\n' "$ROOT" >&2; exit 1; }

USAGE="$ROOT/usage.md"

write_header() {
  cat > "$USAGE" <<'EOF'
# Usage

One row each time a later task actually used a finding from a card. Append-only; the newest row
goes last, so a diff shows only what was added.

Reading a card is not usage, and neither is a row without a ref that resolves. Two kinds:

- `applied` — the finding changed what was done.
- `falsified` — the finding was no longer true when someone relied on it.

`via` records how it was found, which is the part worth debugging: `grep`, `hook`, `readme`,
`memory` (remembered without reading — plausible, and worth a second look).

| Date | Card | Finding | Kind | Via | Ref | What it changed |
| --- | --- | --- | --- | --- | --- | --- |
EOF
}

# A ref resolves or it is a story. `pr:` is the exception: only a person can open it.
ref_problem() {
  local ref="$1" proj="$2" p
  proj=$(cd "$proj" && pwd)
  case "$ref" in
    commit:*)
      git -C "$proj" cat-file -e "${ref#commit:}^{commit}" 2>/dev/null && return 0
      printf 'ref does not resolve: %s' "$ref" ;;
    test:*)
      p="${ref#test:}"
      [ -e "$proj/$p" ] && return 0
      printf 'ref does not resolve: %s' "$ref" ;;
    pr:*) return 0 ;;
    *) printf 'ref is not a token: %s' "$ref" ;;
  esac
  return 1
}

case "$MODE" in
  init)
    if [ -f "$USAGE" ]; then
      printf '%s already exists\n' "$USAGE"
    else
      write_header
      printf 'created %s\n' "$USAGE"
    fi
    exit 0
    ;;
  "")
    printf 'nothing to do: pass --add, --check or --init\n' >&2
    exit 2
    ;;
esac

if [ "$MODE" = "add" ]; then
  fail() { printf 'refused: %s\n' "$1" >&2; exit 1; }

  [ -n "$CARD" ] && [ -n "$FINDING" ] && [ -n "$KIND" ] || fail "usage: --add <card> <F#> <kind> \"<what changed>\" --ref <ref>"

  dir="$ROOT/done/$CARD"
  [ -d "$dir" ] || dir="$ROOT/doing/$CARD"
  [ -d "$dir" ] || fail "no card named $CARD in $ROOT/done or $ROOT/doing"

  case "$KIND" in
    applied | falsified) ;;
    *) fail "kind is applied or falsified, not '$KIND'" ;;
  esac

  grep -qE "^## $FINDING — " "$dir/findings.md" 2>/dev/null ||
    fail "$CARD has no $FINDING — check the heading in findings.md"

  [ -n "$NOTE" ] || fail "one line saying what changed; an empty note proves nothing"

  case "$REF" in
    commit:* | test:* | pr:*) ;;
    *) fail "a ref is required: commit:<sha>, test:<path>, or pr:<n>" ;;
  esac

  case "$VIA" in
    grep | hook | readme | memory) ;;
    *) fail "--via is grep, hook, readme or memory" ;;
  esac

  why=$(ref_problem "$REF" "$(dirname "$ROOT")") || fail "$why"

  [ -f "$USAGE" ] || write_header

  printf '| %s | %s | %s | %s | %s | `%s` | %s |\n' \
    "$(date +%Y-%m-%d)" "$CARD" "$FINDING" "$KIND" "$VIA" "$REF" "$NOTE" >> "$USAGE"

  printf 'recorded: %s %s %s (%s) -> %s\n' "$CARD" "$FINDING" "$KIND" "$REF" "$USAGE"
  exit 0
fi

# --check: every ref has to resolve, and every row has to name a card that exists.
[ -f "$USAGE" ] || exit 0

proj=$(cd "$(dirname "$ROOT")" && pwd)
bad=0

while IFS= read -r line; do
  case "$line" in '| 2'*) ;; *) continue ;; esac
  n=$(printf '%s\n' "$line" | awk -F'|' '{print NF-2}')
  if [ "$n" -ne 7 ]; then
    printf 'usage row has %s cells, needs 7: %s\n' "$n" "$line"
    bad=$((bad + 1)); continue
  fi
  card=$(printf '%s\n' "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$3); print $3}')
  finding=$(printf '%s\n' "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$4); print $4}')
  ref=$(printf '%s\n' "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$7); gsub(/`/,"",$7); print $7}')

  if [ ! -d "$ROOT/done/$card" ] && [ ! -d "$ROOT/doing/$card" ]; then
    printf 'names a card that does not exist: %s\n' "$card"
    bad=$((bad + 1)); continue
  fi

  if ! grep -qE "^## $finding — " "$ROOT/done/$card/findings.md" 2>/dev/null &&
     ! grep -qE "^## $finding — " "$ROOT/doing/$card/findings.md" 2>/dev/null; then
    printf '%s names a finding that does not exist: %s\n' "$card" "$finding"
    bad=$((bad + 1)); continue
  fi

  if ! why=$(ref_problem "$ref" "$proj"); then
    printf '%s\n' "$why"
    bad=$((bad + 1))
  fi
done < "$USAGE"

[ "$bad" -eq 0 ] || exit 1
exit 0
