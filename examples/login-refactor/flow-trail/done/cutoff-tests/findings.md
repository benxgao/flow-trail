# Findings: cutoff-tests

What this card learned. Conclusions live in [`README.md`](./README.md). Ordered by what it costs a
reader **not** to know — not by when it was found. Each entry ends with what cites it.

## F1 — The signing path keys off the secret's presence, so the window never closes by itself

- **Saw** (2026-11-04, before the change) — the algorithm was chosen by a lookup, not a date:

  ```js
  export function algorithmFor(issuedAt) {
    return process.env.JWT_SECRET ? "HS256" : "RS256";
  }
  ```

- **Means** — a secret that exists is a secret that exists forever; a date is the part that ends.
  There was no date anywhere in the path: `grep -c CUTOFF` returned 0.
- **Cost if unknown** — the next person reads "we migrated to RS256" from the title, sees HS256
  still signing, and concludes the migration failed rather than that it was never finished.
- **Cited by** — `app/src/session.js :: CUTOFF` — the two switches; and
  `app/test/session.test.js :: the cutoff itself is the switch`.
- **Status** — fixed; the date decides now, and the secret only decides inside the window.

## Receipts

| What | Command | Output | Date |
| --- | --- | --- | --- |
| Cases on the boundary | `cd app && node --test --test-name-pattern cutoff` | `# pass 3` | 2026-11-04 |
| Switches in the signing path | `grep -c CUTOFF app/src/session.js` | `2` (was `0`) | 2026-11-04 |
