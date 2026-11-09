# Backlog: read the board from a spreadsheet

The board answers one card at a time. A CSV of every card — column, phase, last note date —
would let a spreadsheet answer "what closed this quarter" without opening folders.

- **Trigger** — `done/` holding enough cards that counting them by hand is slower than a script.
- **Sketch** — `scripts/export.sh` prints one row per card: name, column, phase, last note date.
- **Waits on** — nothing to export yet. One closed card is a README, not a table.

## Decisions

| Decision | Why | Rejected alternative |
| --- | --- | --- |
| Read folders, write nothing | Upkeep is a second place to be wrong | A `board.csv` kept by hand |
