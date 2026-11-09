# Changelog

- Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
- Versioning: [SemVer](https://semver.org/).

## Unreleased

### Added

### Changed

### Removed

## 0.1.0 — 2026-11-09

First release.

- Extracted from a private repository after five months of use.
- Tested twice by handing it to an agent that had never seen it.

### Added

- Three columns, each a directory: `backlog/`, `doing/`, `done/`.
- A card is a folder of one to three markdown files; a move is `git mv`.
- `progress.md` is deleted at close, after what it holds moves into the other two files.
- Every `## Decisions` row names the option that was rejected.
- Every `## Measurements` row carries the command that produces the number.
- `SKILL.md` is the whole product. No plugin is needed to read it.
- Five scripts: the card linter, the prose check, the template check, a session-start
  hook, and `verify-outcome.sh` for the Outcome commands of closed cards.
- Four install routes: `npx skills add`, a Claude Code plugin, an `AGENTS.md` pointer,
  and a clone with a symlink.
- `examples/login-refactor` is a board with one card per column, taken from a real run.

### Removed

- The `## Docs` checklist, the `rewrites` counter, the legacy `*-rollout.md` path.
- All three were specific to one repository's history.
