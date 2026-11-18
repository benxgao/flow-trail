#!/usr/bin/env bash
# Installs or upgrades flow-trail at its newest release, detected rather than typed.
#
#   bash bootstrap.sh [--dry-run] [--main] [project-dir]
#
# One ls-remote asks the remote for its newest tag: no API, no token, no version to type.
# Then the owner of this repository's skill is read from the disk — a copy recorded in
# skills-lock.json belongs to `npx skills`, a link into ~/.flow-trail to install.sh — and
# only that one is moved. A project copy wins over a link, so moving the wrong one looks
# like a successful upgrade that changes nothing.
#
# ~/.flow-trail is a dependency of the repository, not work in it: the checkout there is
# forced, and an edit in that folder is not kept.
#
# The last line is the version read back from the manifest, not the one printed by the
# tool that downloaded it.

set -uo pipefail

DRY=0
MAIN=0
ROOT="$PWD"
URL="https://github.com/benxgao/flow-trail"
DEST="$HOME/.flow-trail"

usage() {
  # Pasted as `bash -c "$(curl …)"` there is no file behind $0; the header is the file.
  if [ -f "$0" ]; then awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$0"; return; fi
  printf 'bootstrap.sh [--dry-run] [--main] [project-dir]\n'
  printf 'Installs or upgrades flow-trail at its newest release, detected rather than typed.\n'
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --main) MAIN=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'unknown flag: %s\n' "$arg" >&2; exit 2 ;;
    *) ROOT="$arg" ;;
  esac
done

ROOT=$(cd "$ROOT" 2>/dev/null && pwd -P) || {
  printf 'no such directory: %s\n' "$ROOT" >&2
  exit 2
}

# The manifest is the only file that carries a version.
version_at() {
  sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$1/.claude-plugin/plugin.json" 2>/dev/null | head -1
}

# v1 is newer than v2, by version order and not by string order: 0.10 > 0.9.
is_newer() {
  [ "$1" != "$2" ] || return 1
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]
}

newest_tag() {
  git ls-remote --tags --refs "$URL" 2>/dev/null |
    awk -F/ '{print $NF}' | grep -E '^v[0-9]+\.' | sort -V | tail -1
}

# 1. Who serves this repository's skill, and which version is on disk.
PROJECT_SKILL="$ROOT/.agents/skills/flow-trail"
[ -e "$PROJECT_SKILL" ] || PROJECT_SKILL="$ROOT/.claude/skills/flow-trail"

CURRENT=""
WHERE=""
# One link, one checkout, and copies that a harness reads instead of both.
HARNESS_DIRS=("$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.codex/skills"
  "$HOME/.copilot/skills" "$HOME/.gemini/skills" "$HOME/.dsh/skills"
  "$HOME/.workbuddy-ai/skills" "$HOME/.codebuddy/skills")
HARNESS_COPY=""
for h in "${HARNESS_DIRS[@]}"; do
  [ -L "$h/flow-trail" ] && continue
  [ -e "$h/flow-trail" ] && { HARNESS_COPY="$h/flow-trail"; break; }
done

if [ -e "$PROJECT_SKILL" ] && [ -f "$ROOT/skills-lock.json" ]; then
  OWNER="npx skills (a copy in $ROOT/skills-lock.json)"
  CURRENT=$(version_at "$PROJECT_SKILL")
  WHERE="$PROJECT_SKILL"
elif [ -d "$DEST" ]; then
  OWNER="install.sh (the checkout at $DEST)"
  CURRENT=$(version_at "$DEST")
  WHERE="$DEST"
elif [ -n "$HARNESS_COPY" ]; then
  OWNER="a copy where a link belongs: $HARNESS_COPY"
  CURRENT=$(version_at "$HARNESS_COPY")
  WHERE="$HARNESS_COPY"
else
  OWNER="none: nothing installed in this repository"
fi

# 2. The newest release, unless the tip of main was asked for.
TAG=""
TARGET=""
if [ "$MAIN" -eq 1 ]; then
  TARGET="main (unreleased)"
else
  TAG=$(newest_tag)
  if [ -z "$TAG" ]; then
    printf 'cannot reach %s for its tags\n' "$URL" >&2
    printf 'No download, nothing written. Check the network and run it again.\n' >&2
    exit 2
  fi
  TARGET=${TAG#v}
fi

# 3. A checkout ahead of the newest tag is not a downgrade waiting to happen.
AHEAD=0
if [ "$MAIN" -eq 0 ] && [ -n "$CURRENT" ] && is_newer "$CURRENT" "$TARGET"; then
  AHEAD=1
fi

case "$OWNER" in
  npx*) ACTION="npx skills update flow-trail -y -p" ;;
  *) ACTION="checkout $TARGET at $DEST, then install.sh" ;;
esac

printf '\nflow-trail bootstrap%s\n\n' \
  "$([ "$DRY" -eq 1 ] && printf ' (dry run, nothing written)' || true)"
printf '  release    %s\n' "$TARGET"
if [ -n "$CURRENT" ]; then
  printf '  here       %s (%s)\n' "$CURRENT" "$WHERE"
else
  printf '  here       none\n'
fi
printf '  owner      %s\n' "$OWNER"
printf '  action     %s\n' "$([ "$AHEAD" -eq 1 ] && printf 'none: ahead of the newest tag' || printf '%s' "$ACTION")"

if [ "$DRY" -eq 1 ] || [ "$AHEAD" -eq 1 ]; then
  [ "$AHEAD" -eq 1 ] && printf '\nNewer than the newest tag, so nothing was moved. --main follows the tip.\n'
  [ "$DRY" -eq 1 ] && printf '\nNothing written. Run it again without --dry-run.\n'
  exit 0
fi

# 4. Move the owner that exists. Both routes are idempotent; a second run repairs.
READ_AT=""
case "$OWNER" in
  npx*)
    if ! command -v npx >/dev/null 2>&1; then
      printf '\nnpx is not on PATH, and this repository is owned by it.\n' >&2
      printf 'Install Node, or delete skills-lock.json and .agents/skills/flow-trail to give\n' >&2
      printf 'the link route ownership instead.\n' >&2
      exit 1
    fi
    printf '\n'
    if ! ( cd "$ROOT" && npx skills update flow-trail -y -p ); then
      printf '\nnpx skills update failed; nothing was verified.\n' >&2
      exit 1
    fi
    READ_AT="$PROJECT_SKILL"
    printf '\nThat line reads "up to date" whether or not it updated. The version below does not.\n'
    ;;
  *)
    if [ ! -d "$DEST/.git" ]; then
      printf '\n'
      if [ "$MAIN" -eq 1 ]; then
        git -c advice.detachedHead=false clone -q --depth 1 "$URL" "$DEST" || exit 1
      else
        git -c advice.detachedHead=false clone -q --depth 1 --branch "$TAG" "$URL" "$DEST" || exit 1
      fi
    else
      if [ "$MAIN" -eq 1 ]; then
        git -C "$DEST" fetch -q --depth 1 origin main &&
          git -C "$DEST" -c advice.detachedHead=false checkout -q -f --detach FETCH_HEAD || exit 1
      else
        git -C "$DEST" fetch -q --tags --depth 1 origin "refs/tags/$TAG:refs/tags/$TAG" ||
          git -C "$DEST" fetch -q --tags origin || exit 1
        git -C "$DEST" -c advice.detachedHead=false checkout -q -f --detach "refs/tags/$TAG" || exit 1
      fi
    fi
    # Releases before 0.6.2 refuse a stale copy instead of replacing it. Clearing the
    # copies this skill owns is the step they lack, and a link is left to install.sh.
    for h in "${HARNESS_DIRS[@]}"; do
      p="$h/flow-trail"
      [ -L "$p" ] && continue
      [ -e "$p" ] || continue
      grep -qE '^name:[[:space:]]*flow-trail[[:space:]]*$' "$p/SKILL.md" 2>/dev/null || continue
      rm -rf "$p" && printf '  removing   %s (a copy; a link replaces it)\n' "$p"
    done
    bash "$DEST/scripts/install.sh" "$ROOT" || exit 1
    READ_AT="$DEST"
    ;;
esac

# 5. Read it back from where it was just written. A download that did not land is the
# failure this line catches, and the tool that printed "up to date" cannot catch it.
INSTALLED=$(version_at "$READ_AT")

if [ "$MAIN" -eq 1 ]; then
  printf '\n  installed  %s\n' "${INSTALLED:-unknown}"
  printf '  verdict    main, at whatever the tip holds\n'
  exit 0
fi
if [ "$INSTALLED" = "$TARGET" ]; then
  printf '\n  installed  %s\n' "$TARGET"
  if [ "$CURRENT" = "$TARGET" ]; then
    printf '  verdict    already %s; the links and the board were re-checked\n' "$TARGET"
  else
    printf '  verdict    %s -> %s\n' "${CURRENT:-nothing}" "$TARGET"
  fi
  exit 0
fi

# Two ways this lands: the download did not, or the tag was cut before the manifest
# was bumped. The tag's own commit tells the two apart, and only one of them is a
# problem with this machine.
TAG_SHA=$(git ls-remote "$URL" "refs/tags/$TAG" 2>/dev/null | awk '{print $1}')
if [ "$READ_AT" = "$DEST" ]; then
  AT_SHA=$(git -C "$DEST" rev-parse HEAD 2>/dev/null)
else
  AT_SHA=$(sed -n 's/.*"commit": *"\([^"]*\)".*/\1/p' "$ROOT/skills-lock.json" 2>/dev/null | head -1)
fi

printf '\n  installed  %s\n' "${INSTALLED:-unknown}" >&2
if [ -n "$TAG_SHA" ] && [ "$TAG_SHA" = "$AT_SHA" ]; then
  printf '  verdict    v%s is the code in place, and its manifest says %s\n' \
    "$TARGET" "${INSTALLED:-unknown}" >&2
  printf '  meaning    the tag was cut before the version was bumped; nothing here is broken\n' >&2
  printf '  next       the release needs plugin.json at %s, then a tag that points at it\n' \
    "$TARGET" >&2
else
  printf '  verdict    still %s after moving to %s: the download did not land\n' \
    "${INSTALLED:-unknown}" "$TARGET" >&2
  printf '  next       bash %s/scripts/install.sh --relink %s\n' "$DEST" "$ROOT" >&2
fi
exit 1
