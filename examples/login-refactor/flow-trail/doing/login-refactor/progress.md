---
card: login-refactor
status: open
phases:
  - { id: P1, name: "Cutoff switch in the session service", code: "[x]", verified: "[x]" }
  - { id: P2, name: "Legacy window", code: "[v]", verified: "[ ]" }
  - { id: CL, name: "Close", code: "[ ]", verified: "[ ]" }
next: "P2 — run npm test, then close"
---

# Progress: login-refactor

## Baseline

Measured **before the first edit**, in `app/`, against the version excerpted in
[`findings.md`](./findings.md#the-session-service-before-p1).

| Metric | Before | Command | Output |
| --- | --- | --- | --- |
| Tests | 2 | `cd app && npm test` | `# tests 2`, `# pass 2` |
| Tests naming a cutoff | 0 | `grep -c cutoff test/session.test.js` | `0` |

> Those numbers describe a two-file version that no longer exists in `app/`. It survives only as the
> excerpt in `findings.md`.

## Phases

### P1 — Cutoff switch in the session service

**Goal**: one function decides the algorithm from the issue date, so no caller passes one.

**Files**: `app/src/session.js` (modify) — add `algorithmFor`; `createSession` stops choosing;
`app/test/session.test.js` (modify) — three cases around the boundary.

**Verify**:

```bash
cd app && node --test --test-name-pattern cutoff   # 3 pass, 0 fail
```

**Checklist**:

- [x] **1.1 — `algorithmFor(issuedAt)`**: `HS256` before `CUTOFF`, `RS256` at or after it.
- [x] **1.2 — the boundary is the date**: a token issued at the cutoff is `RS256`.

### P2 — Legacy window

**Goal**: a caller sets its own ttl, so the mobile client stops asking for a second token.

**Files**: `app/src/session.js` (modify) — honour `ttlSeconds`;
`app/test/session.test.js` (modify) — the case below.

**Verify**:

```bash
cd app && npm test   # 5 tests, 5 pass, 0 fail
```

**Checklist**:

- [x] **2.1 — the window is documented**: the comment names both ends.
- [v] **2.2 — `ttlSeconds` honoured**: written, never run. The suite still fails this case.

### CL — Close

- [ ] Durable evidence moved to `findings.md`
- [ ] `## Outcome` carries Before, After and Command
- [ ] Every decision has a `## Decisions` row with its rejected alternative
- [ ] `## Residual` written; "nothing" is valid, silence is not
- [ ] `git rm flow-trail/doing/login-refactor/progress.md`
- [ ] `git mv flow-trail/doing/login-refactor flow-trail/done/login-refactor`

## Session notes

### 2026-10-24 16:40 — P1.1

- Did: `algorithmFor` added; `createSession` now delegates to it.
- Verified by: `node --test --test-name-pattern cutoff` — 3 pass, 0 fail.
- Tried and dropped: a `secretIsStrong()` check deciding the algorithm. Dropped because it makes the
  window depend on an env var, so the migration ends when someone remembers to unset it.
- Next: write the P2 ttl case.
- Blocked on: none.

### 2026-11-05 11:12 — P2.1

- Did: the window comment; `ttlSeconds` accepted in the signature; the ttl case written.
- Verified by: none — the session ended before the suite ran.
- Tried and dropped: computing `exp` in the caller. Dropped because six call sites are six places
  the seven-day default can drift from.
- Next: `cd app && npm test`, then close.
- Blocked on: nobody; one more session is enough.
