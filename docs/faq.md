# FAQ

The questions that did not fit on the [README](../README.md) page, grouped by what a reader is
trying to do.

## The board

- **What if a card is in the wrong column?** `git mv` it. The path is the only record of status.
- **Why not one folder for everything?** `ls` could not then say what is running and what is
  parked. That answer is the board.
- **Does a merge conflict hurt?** Two cards conflict as two files. There is no status column to
  resolve by hand.
- **Can a card go backwards?** Yes: `git mv` it to `backlog/`, delete `progress.md` and
  `findings.md`, trim the README back to the idea. History keeps the detail.
- **Is there a UI, or a hosted board?** No. `ls flow-trail/*/` is the view, and the hook prints
  it at session start.
- **What if the idea in the backlog grows?** Edit the page. It stays one page until someone
  starts it.
- **Can a card stay open for months?** Yes. `next:` and the date of the last note say how long it
  has been waiting.

## The files

- **Why three files and not one?** They die at different times. One file means deleting evidence
  to close a card.
- **What if a card produced no evidence?** `findings.md` stays empty. Empty is valid.
- **How long can a card be?** Closed README 120 lines, findings 200. The linter warns, never
  blocks. `progress.md` is deleted, so its length costs nothing.
- **What if a number stops being true?** `verify-outcome.sh --run` re-runs every `## Outcome`
  command and reports drift.
- **What if a decision turns out wrong?** Add a row. The old row keeps its date and its rejected
  option.
- **Does it clutter the repo?** One to three files per card, two once closed. A closed card is a
  page you can grep.
- **Where do the files live?** In your repository, in git, next to the code. No account, no sync.

## Working with an assistant

- **How does a new session find the board?** A pointer line in `AGENTS.md`, and a hook that
  prints each `next:` line.
- **Does it replace `CLAUDE.md`?** No. That file holds standing rules; a card holds one piece of
  work and where it stopped.
- **Does it need an assistant at all?** No. Three folders and markdown; the skill is what makes an
  assistant maintain them.
- **What stops a card for every typo?** The one-sitting line. One commit, one row in `skips.md`.
- **Two people on one card?** The phases are the lock: one phase, one owner, both read the same row.
- **What if the assistant ignores the board?** The hook prints the folder before the first
  message. A pointer nobody sees is not read.

## Truth and cost

- **Is this scrum?** No sprint, no estimate, no standup, no burndown. The unit is a card, not an
  iteration: it runs until every phase is verified, across as many sessions as that takes.
- **Is it agile for agents?** The columns are a board's shape. The measure is not how fast a team
  moves; it is whether the next session can start from what this one decided.
- **What does a card cost?** One baseline measurement before the first edit, and one `git mv` per
  column change.
- **Do I need all the scripts?** No. They report; none of them gates anything.
- **Can I use it in a repository with no tests?** Yes. `findings.md` holds a command and its
  output, and a command that prints nothing is still evidence.

## Rules and what they cost

- **Why one card in `doing/` at a time?** Two cards mean two `next:` lines, and a new session
  cannot tell which is stale.
- **Why does every decision record the rejected option?** Code keeps the winner. Nothing else
  keeps the loser, and the loser is what the next reader asks about.
- **Why `[v]` and `[x]` apart?** `[x]` means a command ran and printed what the card says.
  Writing it because the code compiles is how "done" stops meaning anything.
- **Why are there only three columns?** Four closing phases were completed 0 times in 7 plans.
  The rest of the measurement: [design notes](../references/design-notes.md).
