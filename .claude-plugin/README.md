# Claude Code marketplace files

- `plugin.json` is the plugin manifest; `marketplace.json` lists this repository as a marketplace.
- Claude Code reads both. Nothing else here depends on them.
- Remove the folder and the `/plugin` route goes away; `SKILL.md` still loads where it did.
- Other harnesses: [load routes](../docs/install.md), hooks in [docs/hooks.md](../docs/hooks.md).
