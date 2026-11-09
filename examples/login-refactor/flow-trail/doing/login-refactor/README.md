# Card: sign sessions by issue date, not by which secret exists

The service signed every token HS256, so a leaked secret could mint one forever. This moves the
choice onto the token's issue date and gives the legacy path an end date.

Detail behind these conclusions: [`findings.md`](./findings.md).

## Outcome

One phase closed, one written and never run. The switch holds; the caller-supplied ttl does not
exist, and a test says so.

| Metric | Before | After | Command |
| --- | --- | --- | --- |
| Tests | 2 pass, 0 fail | 5 tests, 4 pass | `cd app && npm test` |
| Cutoff cases | 0 | 3 pass | `cd app && node --test --test-name-pattern cutoff` |

## Contract

1. **One switch.** A token's algorithm follows its issue date, nothing else — gate:
   `cd app && node --test --test-name-pattern cutoff` → `# pass 3`, `# fail 0`.
2. **The window ends by itself.** The cutoff is a constant, not an env var — gate:
   `grep -c CUTOFF app/src/session.js` → `2`.
   *If broken*: the legacy path has no end date again; restore the constant before deploying.

## Decisions

| Decision | Why | Rejected alternative | Enforced by |
| --- | --- | --- | --- |
| Issue date is the switch | It ends by itself | A present secret: never ends | `session.js:8` |
| 7-day default stays in code | 6 callers, 6 copies | A `ttl` config column | `session.js:5` |
| The choice lives in one function | One deletion closes it | A wrapper per route | `session.js:7` |

The arguments behind the first row, in full: [`findings.md`](./findings.md#why-the-secret-lost).

## Lessons

- **P2 ended with a written test and no run.** The session stopped between writing the case and
  running the suite. Next time: `Verify` closes a session, it does not open one.

## Residual

- **`ttlSeconds` is accepted and ignored** — one edit and one run from closed; the failing case is
  `a caller-supplied ttl wins over the default`.
- **Clock skew is untested** — never measured, and no case covers it.
- **No real client has used the window** — three unit cases and nothing else.

## Where the proof lives

| Question | Where |
| --- | --- |
| Does the switch hold? | `app/test/session.test.js` |
| How was the baseline measured? | `## Baseline` in `progress.md`, excerpt in `findings.md` |
| Why did the secret lose? | [`findings.md`](./findings.md#why-the-secret-lost) |
| What did we see? | [`findings.md`](./findings.md) |
