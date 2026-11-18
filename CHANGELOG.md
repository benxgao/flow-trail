# Changelog

- Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
- Versioning: [SemVer](https://semver.org/).

## Unreleased

## 0.5.0 — 2026-11-19

The usage table had no denominator, so a zero could be read as "this does not work" when it meant
"nobody has been in that part of the code". The denominator was already in the cards.

### Added

- `area` column: commits touching the files a card cites, since the card was written. The citations
  name the files, so the denominator costs nothing to collect and needs no instrumentation.
- `flow-trail-stats.sh` reads a zero in two ways: no commits in the neighbourhood ("nothing was
  available to retrieve"), or commits but no rows ("the chance existed; the recording did not
  happen"). The two need different fixes and used to look identical.
- `docs/evals.md` "The denominator is a proxy": a finding can be used outside the files it cites,
  so `area 0` with `used 2/2` is possible and is not a contradiction.

### Changed

- The empty state names the one number that is already true on day one: the record can re-prove
  itself with `--verify`, even before anything has been reused.


## 0.4.0 — 2026-11-19

Three objections, one of them fatal to the old template: a finding that restates the code is a cache
that can only lie, and nothing stopped one from being written.

### Added

- `Not in the code because` on every finding: the admission test. If a grep in this repo rebuilds
  the claim, the finding must be deleted, not written. Lint E13 counts it per entry.
- `Check` or `Dies when` on every finding, exactly one: a command that exits non-zero when the claim
  stops holding, or the event that makes it false. A claim nobody can notice going false is a
  liability. Lint E14 counts it.
- `docs/evals.md` "What earns a place": landmine, judgement, why-not, restatement — the last two
  do not belong in findings, and the restatement class makes people stop trusting the folder.
- `docs/evals.md` "The maintenance budget": one write, two command-triggered deletions, no review
  cadence.

### Changed

- Template 3 fields are now Saw / Means / Cost if unknown / Not in the code because / Cited by /
  Check-or-Dies-when / Status.
- Every finding in the reference card and the example board was rewritten against the new test; two
  of them passed only by being explicit about what they are not.

### Removed

- The idea that a finding can be "just evidence". Evidence that the repository already holds is a
  copy, and a copy has one behaviour: it goes stale.


## 0.3.1 — 2026-11-19

One label, corrected. The footer said "of N with a citation", and N was every finding, cited or
not — a label naming a different set than it counts is the defect this release line is about.

### Changed

- `flow-trail-stats.sh` prints "N of M finding(s) used at least once".

## 0.3.0 — 2026-11-19

`stats.sh` measured the card. Nothing measured the later task that read it. A log now records that
event, and the skill asks for it at the three moments it can still happen.

### Added

- `flow-trail/usage.md`: append-only, one row per event. Two kinds only — `applied` (a finding
  changed what was done) and `falsified` (it was no longer true when someone relied on it). `via`
  records `grep`, `hook`, `readme` or `memory`: which surface actually delivers a finding.
- `scripts/flow-trail-usage.sh` with `--add`, `--check` and `--init`. `--add` refuses a row with no
  ref, a finding the card does not have, or an empty description.
- `docs/evals.md`: the four numbers, the silence triage, the canary — one deliberately wrong
  finding, so a quiet log can be told from a working one — and the monthly audit.
- Lint E12 resolves every usage ref: a `commit:` must exist, a `test:` must exist. W5 warns when a
  closed card has findings and no event after `FLOW_TRAIL_SILENT_DAYS` (default 30).
- `flow-trail-stats.sh` grows a usage table under the card table: findings used, applied, falsified,
  first use, via — plus the list of findings nothing has used.
- `session-start.sh` prints the `--add` command under the closed-card line. The instruction that
  decays fastest is the one nobody repeats.

### Changed

- `progress.md` session notes gain `- Used: <card F#> — <what changed>`, and the close checklist
  asks whether an earlier card was used. Both exist so the row is written while the session still
  knows what happened, not reconstructed a week later.
- `install.sh` creates `usage.md` with the board.
- Lint is seventeen checks: twelve errors, five warnings.

## 0.2.3 — 2026-11-18

The reference card still cited `session.js:5` in its `Enforced by` column, which is the same rot in
the column next door. Same anchor, no line numbers.

### Changed

- `examples/login-refactor`: five `Enforced by` cells name a string instead of a line. The rule is
  not extended to that column on purpose — it may name a section or a function
  (`## Contract 1–2`, `upstreamFailure()`), so a checker there would need exceptions, and a rule
  with exceptions is the ceremony this skill deletes.

## 0.2.2 — 2026-11-18

A citation that names a line number is false after the next commit above it, and no check could say
whether it moved or died. A citation now names a string, and the linter greps it.

### Added

- `Cited by` takes `path :: a string that must still be in that file` instead of `path:line`. Lint
  check E11 resolves every citation: a missing file, or a string that is gone, is an error.
- A citation written as `path:line` still parses and warns (W4) — nothing can check it, and a
  warning is the honest signal.
- `scripts/flow-trail-stats.sh`: one row per card — edited, findings, cited, Outcome rows, how
  many carry a `Verify` assertion, manual, lines — then one line of totals. Read-only. `--verify`
  adds an `ok/drift` column and runs the recorded commands; `--brief` is the line the hook shows.
- FAQ: why a line number is the wrong address, and how to tell whether anyone uses the board.

### Changed

- `session-start.sh` delegates its closed-card line to `flow-trail-stats.sh --brief`, so the hook
  and the table agree on which cards count as recent. The inline loop stays as a fallback.
- `verify-outcome.sh` runs recorded commands from the project root (`dirname <root>`) rather than
  from the reader's working directory. Running a board from a parent folder used to turn every
  `cd app && …` row into a DRIFT.
- Lint is fifteen checks: eleven errors, four warnings.

## 0.2.1 — 2026-11-18

Findings were logs. Twenty rows saying the suite passed 128 times, and the one entry that mattered
last. A finding is now numbered, priced, and cited.

### Added

- `## Outcome` takes an optional fifth column, `Verify`: one assertion that exits 0 while the After
  value is still true. `verify-outcome.sh` runs it and reports `ok` or `DRIFT`.
- Three linter checks: every findings heading is `## F<n> —` (`## Reference` and `## Receipts`
  allowed); each `F` entry carries `Cost if unknown` and `Cited by`; a closed README never points at
  `progress.md`.
- `session-start.sh` names the three most recently closed cards. Before this, a `done/` card had no
  automatic surface at all — the `doing/` loop skips it, so an agent only found the archive by
  grepping for something it did not know existed.

### Changed

- Template 3 is findings-first: `F1..Fn`, ordered by cost to the reader, not by date. Each has
  Saw / Means / Cost if unknown / Cited by / Status, then optional `## Reference`, `## Receipts`.
- `verify-outcome.sh` separates strict from loose. A row without a `Verify` cell is `LOOSE`: the
  recorded text only has to appear in the output, so prose never matches and never fails the run.
  The previous version reported 12 of 12 rows as drifted on a healthy card, which teaches people to
  ignore a checker — that is worse than having none.
- `verify-outcome.sh` accepts `manual` in the `Verify` cell for a check that needs a deployed stage
  or a secret, and skips it rather than failing on every run.
- The `Outcome` template requires the command alone in the Command cell. An Arrow-and-expected-value
  form (`grep … → 1`) is what `bash -c` cannot run, and is what made two rows exit 2.
- `docs/files.svg`, `docs/how-it-works.md` and `docs/faq.md` show the numbered structure.

### Removed

- `## Measurements` as a findings heading, and with it the template's licence to keep a progress bar
  after the progress is gone. Those rows are `## Receipts` now, or deleted.

## 0.2.0 — 2026-11-18

One paste at the agent, and the installer writes what a user used to configure by hand.

### Added

- `scripts/install.sh`: links the skill into every harness folder this machine has, appends the
  `AGENTS.md` pointer, adds the ignore lines, creates `flow-trail/`. Idempotent, `--dry-run`.
- `docs/install.md` opens with a paste block for an agent; `npx skills add` drops to the last
  section, as the older route.

### Changed

- README puts Get started above "Is it for you", and the install is one paste instead of a CLI
  plus a per-harness caveat.
- `docs/install.md`: twelve per-harness sections become two tables, the folder each reads and what
  is left to the user.
- `SKILL.md` "First card in a repository" writes only what the installer did not.

### Removed

- The "WorkBuddy and editors that read only `AGENTS.md` need one more step" caveat: the installer
  writes the link and the pointer.

## 0.1.2 — 2026-11-17

Installed is not loaded. A session that never names the board gets an answer, not a card.

### Added

- Install section "Then give it a way in": the pointer, the hook, and what happens with neither.
- FAQ entry "Installed, and no card appeared?", with `ls flow-trail/` as the test.

### Changed

- README says the install does not make the board get used, and the first session needs a way in.
- The WorkBuddy section links at user level: that is the folder the app lists.

## 0.1.1 — 2026-11-09

Install routes and the places it runs, from the first week.

### Added

- FAQ section "Where it runs": Windows needs WSL or Git Bash; a folder outside git loses
  `git log --follow`.
- WorkBuddy and CodeBuddy install steps, with the symlink `npx skills add` does not create.
- Two checks that tell a wired session-start hook did not fire.

### Changed

- `docs/install.md` names `npx skills add` as the one route run end to end.
- README states the measurement was on Claude Code, and that the history starts at extraction.
- `references/design-notes.md` trimmed; `SKILL.md` no longer lists it among the files.

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
