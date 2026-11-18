# Findings: login-refactor

What this card learned so far. Conclusions live in [`README.md`](./README.md). Ordered by what it
costs a reader **not** to know — not by when it was found. Each entry ends with what cites it.

## F1 — The cutoff test fails because the ttl is ignored, not because the date is wrong

- **Saw** (2026-11-05, `cd app && npm test`) — five tests, one failure, verbatim:

  ```
  not ok 5 - a caller-supplied ttl wins over the default
    expected: 3600
    actual: 604800
  ```

- **Means** — the signing path hard-codes the week:

  ```js
  export function algorithmFor() {
    return "HS256";
  }

  export function createSession({ user, issuedAt }) {
    const iat = Math.floor(issuedAt / 1000);
    return { sub: user.id, alg: "HS256", iat, exp: iat + WEEK };
  }
  ```

  So the algorithm is not the only thing the refactor has to move: the expiry is written into the
  constructor, and the test that proves the cutoff works cannot pass until it is a parameter.
- **Cost if unknown** — the failure reads as "the cutoff logic is wrong", and a day goes into the
  date comparison while the real defect is an argument that never reaches the function.
- **Not in the code because** — `ttlSeconds` is in the signature, so the code reads as if it were
  used. The fact sits on one line (`exp: iat + WEEK`); what the code cannot say is that the line is
  a defect rather than a default. Facts live in the code, judgements do not.
- **Cited by** — `app/test/session.test.js :: a caller-supplied ttl wins over the default`.
- **Dies when** — P2.3 turns `ttl` into a parameter: the test goes green and this is history.
- **Status** — P2.2, being written.

## F2 — The signing secret is present in every environment today

- **Saw** (2026-11-05) — the secret is set in all environments, including the two that nobody
  redeployed since the change.
- **Means** — "enable HS256 whenever the secret is present" is not a migration, it is a switch
  that turns itself on everywhere at once.
- **Cost if unknown** — the window opens in environments nobody watches, and it closes only when
  the last person remembers to unset a variable. No date, no test, and no way to tell a finished
  migration from a forgotten one.
- **Not in the code because** — environment variables are not in this repository. The repo can
  show that a secret is read; it cannot show it is set in every environment, including the two
  nobody redeployed.
- **Cited by** — `README.md :: Issue date is the switch` — the row rejecting the env-var switch.
- **Dies when** — the last environment stops setting the secret. Then the env-var switch would be
  safe, and the cutoff buys nothing.
- **Status** — drove the choice of a cutoff date over a flag.

## F3 — Clock skew is unmeasured

- **Saw** (2026-11-05) — nothing. No host has been tested with a skewed clock.
- **Means** — a host 30 seconds slow issues a token stamped before midnight on the cutoff date;
  that token takes the HS256 path.
- **Cost if unknown** — whether that matters depends on the verifier's tolerance, so the answer
  would be invented by whoever reads the card next instead of measured. This is the first thing to
  check if a post-cutoff token is ever accepted.
- **Not in the code because** — clock skew is a property of the hosts, and the hosts are not here.
  Nothing in the repository says how far a machine's clock drifts.
- **Cited by** — nothing yet. No case exercises it.
- **Dies when** — a case covers an `issuedAt` in the future, which is the proof that was missing.
- **Status** — open.

## Receipts

| What | Command | Output | Date |
| --- | --- | --- | --- |
| Tests, before P1 | `cd app && npm test` | `# tests 2`, `# pass 2` | 2026-11-05 |
| Tests, after P2.2 | `cd app && npm test` | `# tests 5`, `# pass 4`, `# fail 1` | 2026-11-05 |
| Cutoff cases only | `node --test --test-name-pattern cutoff` | `# pass 3`, `# fail 0` | 2026-11-05 |

The middle row is the failure quoted in F1. It stays until P2.3 turns it green; then it becomes the
first row of the closed card's table.
