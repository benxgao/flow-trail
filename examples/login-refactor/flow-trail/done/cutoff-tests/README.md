# Card: pin the signing algorithm to the issue date

Tokens were signed HS256 for as long as the secret existed, so the legacy path had no end. The
algorithm now follows the token's issue date, and three cases cover the boundary.

Detail behind these conclusions: [`findings.md`](./findings.md).

## Outcome

The switch is a date, not a secret. The boundary runs on the same runner as everything else.

| Metric | Before | After | Command |
| --- | --- | --- | --- |
| Cases in the suite | 2 | `5` | `grep -c '^test(' app/test/session.test.js` |
| Boundary cases | 0 | `# pass 3` | `cd app && node --test --test-name-pattern cutoff` |

## Contract

1. **A date decides.** The algorithm follows `issuedAt` and nothing else — gate:
   `cd app && node --test --test-name-pattern cutoff` → `# fail 0`.
2. **The cutoff is code.** Not an env var, so no deploy can move the window — gate:
   `grep -c CUTOFF app/src/session.js` → `2`.

## Decisions

| Decision | Why | Rejected alternative | Enforced by |
| --- | --- | --- | --- |
| Issue date is the switch | It ends by itself | A present secret: never ends | `session.js:5` |
| The cutoff is a constant | One file to read | An env var: a second wrong place | `session.js:5` |
| Test both sides | Off-by-a-day is the bug class | One case mid-window | `test/session.test.js:8` |

## Lessons

- **None yet.**

## Residual

- **The `ttl` case is written and never run** — carried by
  [`doing/login-refactor`](../../doing/login-refactor/README.md), which owns the failing case.
- **Clock skew is untested** — no case covers an `issuedAt` in the future.

## Where the proof lives

| Question | Where |
| --- | --- |
| Does the switch hold? | `app/test/session.test.js` |
| How was it measured? | `## Outcome` above |
| Why the secret lost? | `## Decisions` above |
| What did we see? | [`findings.md`](./findings.md) |
