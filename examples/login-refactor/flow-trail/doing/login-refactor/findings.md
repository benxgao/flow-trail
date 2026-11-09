# Findings: login-refactor

Evidence collected while working. Conclusions live in [`README.md`](./README.md); state lives in
`progress.md`. Anything here should be something a reader can point at.

## Measurements

| What | Command | Output |
| --- | --- | --- |
| Tests, before P1 | `cd app && npm test` | `# tests 2`, `# pass 2` |
| Tests, after P2.2 was written | `cd app && npm test` | `# tests 5`, `# pass 4`, `# fail 1` |
| Cutoff cases only | `node --test --test-name-pattern cutoff` | `# pass 3`, `# fail 0` |

The one failure, verbatim, 2026-11-05:

```
not ok 5 - a caller-supplied ttl wins over the default
  expected: 3600
  actual: 604800
```

## Why the secret lost

The rejected option was: enable the HS256 path whenever the signing secret is present in the
environment.

- It reads as a migration and behaves as a switch nobody owns.
- The secret is present in every environment today, including the two nobody redeployed.
- So the window opens everywhere at once, and it closes when the last person remembers to unset a
  variable.
- That is unbounded: no date, no test, and no way to tell a finished migration from a forgotten one.
- The cutoff date fails in the other direction, which is the useful direction: a token issued after
  2026-01-01 is RS256 even if the secret is still set. The window closes whether or not anyone acts.

## The session service before P1

The excerpt the Baseline table in `progress.md` was measured against. There was no choice yet; the
algorithm was written into the function.

```js
export function algorithmFor() {
  return "HS256";
}

export function createSession({ user, issuedAt }) {
  const iat = Math.floor(issuedAt / 1000);
  return { sub: user.id, alg: "HS256", iat, exp: iat + WEEK };
}
```

## What the window costs

- A token issued before the cutoff stays verifiable with a shared secret for seven days after issue.
- After the cutoff the HS256 path signs nothing new, so the secret stops being a way to mint tokens.
- The cost is the seven days: revoking the old secret early invalidates every token still inside it.

## Clock skew, unmeasured

- A host whose clock runs 30 seconds slow issues a token stamped before midnight on 2025-12-31.
- That token takes the HS256 path. Whether that matters depends on the tolerance of the verifier.
- Nobody has measured it. There is no case for it.
