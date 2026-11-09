#!/usr/bin/env bash
# Checks the five templates in SKILL.md against the prose cap.
#
#   bash template-lint.sh [file ...]      # default: SKILL.md
#
# Why it exists: SKILL.md says "copy verbatim", so a line over the cap in a
# template becomes a finding in every track that copies it. Twelve did.
# prose-lint.sh exempts fenced blocks, so nothing else looked at them.

set -uo pipefail

MAX=100
files=("$@")
[ "${#files[@]}" -gt 0 ] || files=("SKILL.md")

for f in "${files[@]}"; do
  [ -f "$f" ] || { printf '%s not found\n' "$f"; exit 1; }
done

findings=$(awk -v max="$MAX" '
  function ticks(line,   t) { t = line; sub(/^[[:space:]]*/, "", t); sub(/[^`].*$/, "", t); return length(t) }
  FNR == 1 { fence = 0; inner = 0; blocks = 0 }
  {
    n = ticks($0)
    # inside a nested fence: only a run of the same length or longer closes it
    if (inner > 0) { if (n >= inner) inner = 0; next }
    # a run as long as the opener closes the template
    if (fence > 0 && n >= fence) { fence = 0; next }
    # opening a template block
    if (fence == 0 && $0 ~ /^[[:space:]]*`{3,}markdown[[:space:]]*$/) { fence = n; blocks++; next }
    # any other fence inside the template is code, and code is exempt
    if (fence > 0 && n > 0) { inner = n; next }
    if (fence > 0 && length($0) > max) {
      printf "%s:%d: %d bytes in template %d (max %d)\n", FILENAME, FNR, length($0), blocks, max
      bad++
    }
  }
  END {
    if (blocks == 0) printf "%s: no markdown template blocks found\n", FILENAME
    exit (bad > 0)
  }
' "${files[@]}" 2>&1) || true

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  printf '\n%s finding(s) in %d file(s)\n' "$(printf '%s\n' "$findings" | wc -l | tr -d ' ')" "${#files[@]}"
  exit 1
fi

printf '%d file(s), 0 findings\n' "${#files[@]}"
