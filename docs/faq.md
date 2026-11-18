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
- **Is the backlog a roadmap?** It reads like one, because it is the list of what you meant to
  build. Nothing converts it into one: no dates, no quarters, no priorities beyond the order the
  pages arrived in.
- **Does the backlog go stale?** Only if nothing edits it. A closed card writes its leftover line
  onto the page it came from, and a plan in the same area starts the page or says in one line why
  it stays parked. A page nobody has touched in a year is a page nobody wants.
- **Can a card stay open for months?** Yes. `next:` and the date of the last note say how long it
  has been waiting.

## The files

- **Why three files and not one?** They die at different times. One file means deleting evidence
  to close a card.
- **What if a card produced no evidence?** `findings.md` stays empty. Empty is valid.
- **How long can a card be?** Closed README 120 lines, findings 200. The linter warns, never
  blocks. `progress.md` is deleted, so its length costs nothing.
- **What if a number stops being true?** `verify-outcome.sh --run` re-runs every `## Outcome`
  command. A row with a `Verify` assertion is strict; one without is `LOOSE` and never fails the
  run, because prose cannot match output and a checker that always fails gets ignored.
- **Why do findings have numbers?** Because `Cited by` needs an address. `#F1` in a test comment
  turns "this evidence was worth keeping" into a grep, and a finding nobody cites is the first
  entry to retire.
- **Why not cite a line number?** Because the next commit above it makes it false, and no check can
  tell a moved citation from a dead one. `path :: a string that must still be in the file` survives
  the move and fails the lint when the string goes away.
- **How do I know whether anyone is using the board?** `flow-trail-stats.sh` prints one row per
  card. `cited` says what the card points at; the usage table under it says what a later task
  actually consumed. Only the second is about retrieval.
- **Why would an agent read this instead of the code?** Because code answers questions and never
  raises them. Nothing in `src/` suggests "does the upstream drop fields the workspace has not
  defined?" — a reader who does not suspect it will not grep for it. The second reason is cost:
  one runtime fact otherwise costs a handler, a client, a fixture and a test that does not exist.
- **What should never become a finding?** Anything a grep in this repo can rebuild. That is a cache
  of the code with no upside and one failure mode: it lies after the next commit. The field that
  forces the question is `Not in the code because`, and "you grep it and you know" is a delete.
- **What if a finding goes stale?** That is what `Check` and `Dies when` are for: every finding
  carries a command that fails, or the event that makes it false, so staleness is loud rather than
  silent. A finding with neither is a liability and fails the lint.
- **What counts as usage?** A finding that changed what was done, or one that turned out to be
  false. Reading a card is not usage, and neither is a row whose `ref` does not resolve.
- **Who writes the row?** The session that used the finding, before it ends, with
  `flow-trail-usage.sh --add`. The session-start hook prints the command so nobody has to remember
  the shape.
- **What if nobody ever writes one?** Then the board is a diary, and the usage table saying `0
  events` is the honest finding. `docs/evals.md` has the control that tells a quiet log from a
  working one.
- **Why is `## Measurements` gone?** It was a log. A number that only proves the work happened
  belongs under `## Receipts`, where deleting it costs nothing.
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
- **Installed, and no card appeared?** Nothing named a board: no "plan this", no pointer in
  `AGENTS.md`, no `flow-trail/` folder to find. A skill fires on its description, not on install.
  Test it with `ls flow-trail/`; empty means it never fired.
- **Do I configure anything after installing?** No. `scripts/install.sh` writes the pointer, the
  ignore lines and the board; [install](install.md) is the paste block that runs it.

## Truth and cost

- **Is this scrum?** No sprint, no estimate, no standup, no burndown. The unit is a card, not an
  iteration: it runs until every phase is verified, across as many sessions as that takes.
- **Is it agile for agents?** The columns are a board's shape. The measure is not how fast a team
  moves; it is whether the next session can start from what this one decided.
- **What does a card cost?** One baseline measurement before the first edit, and one `git mv` per
  column change.
- **Do I need all the scripts?** No. They report; none of them gates anything.
- **Can I use it in a repository with no tests?** Yes. A finding is what you saw and what it costs
  not to know; a command that prints nothing is still evidence, and so is an absence.
- **What is `falsified`?** Someone relied on a finding and it was no longer true. That row is the
  good one: the record was read, checked, and a claim retired instead of quietly misleading the next
  person. A folder where nothing is ever wrong is a folder nobody is checking.
- **Is a table full of zeros bad?** For two or three weeks, no. The first card has nothing to be
  reused by; the value starts when a second task touches the same code. The table separates the two
  zeros: no commits in the area means nothing was available, commits with no rows means nobody wrote
  it down.
- **How long until it pays for itself?** One avoided afternoon. In practice that arrives with the
  second card, when someone nearly rebuilds what the first card argued against.
- **Why would a finding be deleted?** Silence plus greppable means it was never needed, and a
  shorter card gets read more often than a longer one.
- **Who writes `usage.md`?** The session that used the finding, before it ends. The hook prints the
  command so nobody has to remember the shape.

## Where it runs

- **Windows?** The scripts and the hook are bash; lint and the session line need WSL or Git Bash.
  A card is markdown and opens anywhere.
- **A folder that is not a git repository?** Moves become `mv`, so `git log --follow` is gone.
  The board still reads; the trail does not.

## Rules and what they cost

- **Why one card in `doing/` at a time?** Two cards mean two `next:` lines, and a new session
  cannot tell which is stale.
- **Why does every decision record the rejected option?** Code keeps the winner. Nothing else
  keeps the loser, and the loser is what the next reader asks about.
- **Why `[v]` and `[x]` apart?** `[x]` means a command ran and printed what the card says.
  Writing it because the code compiles is how "done" stops meaning anything.
- **Why are there only three columns?** Four closing phases were completed 0 times in 7 plans.
  The rest of the measurement: [design notes](../references/design-notes.md).
