# Usage

One row each time a later task actually used a finding from a card. Append-only; the newest row
goes last, so a diff shows only what was added.

Reading a card is not usage, and neither is a row without a ref that resolves. Two kinds:

- `applied` — the finding changed what was done.
- `falsified` — the finding was no longer true when someone relied on it.

`via` records how it was found, which is the part worth debugging: `grep`, `hook`, `readme`,
`memory` (remembered without reading — plausible, and worth a second look).

| Date | Card | Finding | Kind | Via | Ref | What it changed |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-11-19 | cutoff-tests | F1 | applied | grep | `test:app/test/session.test.js` | a new spec chose the algorithm by the secret again; F1's 'a date is the part that ends' stopped it |
| 2026-11-19 | login-refactor | F2 | applied | hook | `test:app/test/session.test.js` | kept the cutoff a constant instead of adding a flag, because the secret is set everywhere today |
