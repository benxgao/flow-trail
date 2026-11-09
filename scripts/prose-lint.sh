#!/usr/bin/env bash
# Checks the mechanical half of docs/writing.md: line length, and the four
# filler words the standard bans.
#
#   bash prose-lint.sh [file ...]      # default: every *.md under the repo root
#
# Code fences are exempt from the length check: a command is as long as it is.
# Reports; exits 1 when it finds something.

set -uo pipefail

MAX=100
FILLER='clearly|simply|note that|it is important'

files=("$@")
if [ "${#files[@]}" -eq 0 ]; then
  # .workbuddy-ai and node_modules hold notes and dependencies, not this repo's docs.
  while IFS= read -r f; do files+=("$f"); done < <(
    find . \( -name .git -o -name node_modules -o -name .workbuddy-ai -o -name .history \) -prune \
      -o -name '*.md' -print | sort
  )
fi

[ "${#files[@]}" -gt 0 ] || { echo "no markdown files found"; exit 0; }

findings=$(awk -v max="$MAX" -v filler="$FILLER" '
  FNR == 1 { fence = 0; front = 0 }
  FNR == 1 && /^---$/ { front = 1; next }
  front && /^---$/ { front = 0; next }
  front { next }
  /^[[:space:]]*`{3,}/ {
    t = $0
    sub(/^[[:space:]]*/, "", t)
    sub(/[^`].*$/, "", t)
    n = length(t)
    if (fence == 0) { fence = n; next }
    if (n >= fence) { fence = 0; next }
  }
  fence { next }
  index($0, "prose-lint:ignore") { next }
  length($0) > max {
    printf "%s:%d: %d chars (max %d)\n", FILENAME, FNR, length($0), max
    n2++
  }
  tolower($0) ~ filler {
    printf "%s:%d: filler word: %s\n", FILENAME, FNR, $0
    n2++
  }
  END { exit (n2 > 0) }
' "${files[@]}" 2>&1) || true

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  printf '\n%s finding(s) in %d file(s)\n' "$(printf '%s\n' "$findings" | wc -l | tr -d ' ')" "${#files[@]}"
  exit 1
fi

printf '%d file(s), 0 findings\n' "${#files[@]}"
