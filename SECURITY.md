# Security

- A skill: instructions an AI assistant loads and follows.
- No runtime, no service, no network calls.
- The risk is not a remote exploit. It is an assistant doing something to your repo because these
  instructions told it to.

## What this skill does to your files

The complete list:

- Creates markdown files inside `flow-trail/`.
- Appends one paragraph to `AGENTS.md` or `CLAUDE.md`, on the first card in a repository.
- Deletes `flow-trail/doing/<card>/progress.md` when a card closes, and moves the folder to `done/`.

- Nothing else in your repository is touched.
- Nothing is written outside it.
- An instruction here that does more than that is a bug worth reporting privately.

## Reporting a vulnerability

Email **hi@benxgao.com** with:

- what the instructions make an assistant do that they should not
- the file and line, and the smallest prompt that triggers it
- what you expected instead

- Acknowledgement within 72 hours.
- A valid report is fixed in the next release and credited, unless you ask otherwise.
- Do not open a public issue: a payload posted publicly is a payload someone will try.

## Out of scope

- **Your assistant's own behaviour.** If it deletes the wrong file while following some other
  instruction, that belongs to its vendor.
- **Third-party skills.** No dependencies here. Combined with something else, look there.
- **The `AGENTS.md` paragraph.** Remove it if you disagree; the skill still works by name.

## Supported versions

Current `master` only. No backports: a few hundred lines of markdown and five bash scripts.
