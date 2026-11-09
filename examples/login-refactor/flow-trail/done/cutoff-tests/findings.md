# Findings: cutoff-tests

Evidence collected while working. Conclusions live in [`README.md`](./README.md).

## Measurements

| What | Command | Output |
| --- | --- | --- |
| Cases on the boundary | `cd app && node --test --test-name-pattern cutoff` | `# pass 3` |
| Switches in the signing path | `grep -c CUTOFF app/src/session.js` | `2` |

## The window before the change

The signing path as it stood on the last commit that used it:

```js
export function algorithmFor(issuedAt) {
  return process.env.JWT_SECRET ? "HS256" : "RS256";
}
```

A secret that exists is a secret that exists forever. A date is the part that ends.
