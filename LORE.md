# LORE

- This repository researches AI CLI tools: it tracks upstream skills, plugins, and MCP servers as git submodules, and maintains research docs, user-level setting templates, installers, and local sync and governance workflows.
- It is not a distributable plugin; [.agents/skills](.agents/skills/) holds project skills used only to maintain this repository.

## Directory Index

- [upstream](upstream/) — upstream git submodules; MUST NOT modify their content directly; overview in [UPSTREAM.md](upstream/UPSTREAM.md)
- [cli-agents](cli-agents/) — AI CLI reference docs, user-level setting templates, and one-click installers that write to the user's home directory; overview in [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md)
- [scripts](scripts/) — repo maintenance and automation scripts; [SCRIPTS.md](scripts/SCRIPTS.md) is the single index
- [tool](tool/) — local tool docs and PowerShell profile scripts; overview in [TOOL.md](tool/TOOL.md)
- [ide](ide/) — IDE configuration notes
- [.agents/skills](.agents/skills/) — project skills and the shared upstream sync protocol
- [.github/dependabot.yml](.github/dependabot.yml) — daily check for upstream submodule updates

## Maintenance Rules

- When adding, removing, renaming, or materially changing a script under [scripts](scripts/), MUST update [SCRIPTS.md](scripts/SCRIPTS.md) in the same slice; a new script MUST document at least purpose, arguments, behavior, risks or side effects, and a minimal usage example.
- When a script change makes an entry or summary in [README.md](README.md) stale, MUST update README.md in the same slice.
- When adding, removing, or materially changing a one-click installer under [cli-agents](cli-agents/) or [tool](tool/), MUST update the one-click installer table in [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md) in the same slice.
- [install-statusline.ps1](cli-agents/claude-code/install-statusline.ps1) and [tool/PowerShell/install.ps1](tool/PowerShell/install.ps1) overwrite existing files at their destination without backup.

## Document Structure

- Rules shared by every agent live in [LORE.md](LORE.md); host entry files hold only routing or rules for that host alone.
- `LORE`, `AGENTS`, `CLAUDE`, and `CODEX` MUST each have an English file without suffix and an equivalent Traditional Chinese file with the `_ch` suffix; MUST update both in the same change. Any other agent document MAY add a `_ch` counterpart, and the pair MUST then stay equivalent. A `_ch` file links to `_ch` targets when they exist.
- Agent documents hold only stable rules; MUST NOT write task progress, temporary state, or ongoing migrations into them.
- [README.md](README.md) is a Traditional Chinese human-reader document.
- Project skills live in `.agents/skills/<skill-name>/`; MUST NOT create skill files directly under `.claude/skills`, which is a local link to `.agents/skills`.

## Reading Guide

- [UPSTREAM.md](upstream/UPSTREAM.md) when adding, syncing, or installing an upstream project.
- [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md) when working on the CLI reference docs, setting templates, or one-click installers, or when deciding between an agent and a skill.
- [SCRIPTS.md](scripts/SCRIPTS.md) when running or changing a script under `scripts/`.
- [TOOL.md](tool/TOOL.md) when working on the PowerShell profile or tool scripts.
- [sync-all](.agents/skills/sync-all/SKILL.md) when processing Dependabot submodule update PRs.
- [anthropic-skills-sync](.agents/skills/anthropic-skills-sync/SKILL.md) when syncing the `anthropic-skills` upstream.
- [cli-doc-sync](.agents/skills/cli-doc-sync/SKILL.md) when aligning CLI reference docs with the official docs.
- [skills-governance](.agents/skills/skills-governance/SKILL.md) when creating, modifying, renaming, or removing a project skill.
