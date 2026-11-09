# Writing

Docs are read by scanning, not by reading. Every file in this repository follows the rules below.

Applies to every markdown file here: root pages, `SKILL.md`, `docs/`, `references/`,
`.claude-plugin/`, `examples/`, and every card's `README.md`, `findings.md`, `progress.md`.

## The ten rules

1. One idea per line.
2. Bullets over paragraphs.
3. Keep lines under ~100 characters.
4. Facts only — no background, motivation, or history.
5. No filler: "clearly", "simply", "note that", "it is important". <!-- prose-lint:ignore -->
6. Do not restate the title in the first bullet.
7. Reference other artifacts by ID; never repeat their content.
8. One level of nesting at most.
9. Omit a section that has nothing to say.
10. If a bullet needs two sentences, it is two bullets.

## Why these rules

- Scanning finds a fact; reading a paragraph finds an opinion.
- A long line hides its own point at the wrap.
- History belongs in git, not in the doc.

## Mechanical checks

- Line length and the four filler words: `bash scripts/prose-lint.sh`.
- Lines inside the `SKILL.md` templates, which that script skips as fenced code:
  `bash scripts/template-lint.sh`.
- The cap counts bytes: each em dash costs two extra, so a line with two wraps at 96.
- A rule a command cannot check is a rule people learn by reading examples.
- Read the two files below before writing prose; both follow the rules.

## Exceptions

- Code blocks are exempt from the line limit.
- Quoted output is exempt: it is evidence, not writing.
- A line needing a banned word carries `<!-- prose-lint:ignore -->`.
- A one-sentence intro under a title is allowed; a second sentence is not.
