# AGENTS.md

- This repository researches AI CLI tools: it tracks upstream skills, plugins, and MCP servers as git submodules, and maintains research docs, user-level setting templates, installers, and local sync and governance workflows.
- It is not a distributable plugin; [.claude/skills](.claude/skills/) holds project skills used only to maintain this repository.

## Directory Index

- [upstream](upstream/) — upstream git submodules; MUST NOT modify their content directly; overview in [UPSTREAM.md](upstream/UPSTREAM.md)
- [cli-agents](cli-agents/) — AI CLI reference docs, user-level setting templates, and one-click installers that write to the user's home directory; overview in [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md)
- [scripts](scripts/) — repo maintenance and automation scripts; [SCRIPTS.md](scripts/SCRIPTS.md) is the single index
- [tool](tool/) — local tool docs and PowerShell profile scripts; overview in [TOOL.md](tool/TOOL.md)
- [.claude/skills](.claude/skills/) — project skills and the shared upstream sync protocol
- [.github/dependabot.yml](.github/dependabot.yml) — daily check for upstream submodule updates

## Notes

- `AGENTS.md` is the English primary version and `AGENTS_ch.md` is its Traditional Chinese mirror; any change to either MUST update both in the same change slice, and MUST NOT leave one language stale to sync later.
- When adding, removing, renaming, or materially changing a script under [scripts](scripts/), MUST update [SCRIPTS.md](scripts/SCRIPTS.md) in the same slice; a new script MUST document at least purpose, arguments, behavior, risks or side effects, and a minimal usage example.
- When a script change makes an entry or summary in [README.md](README.md) stale, MUST update README.md in the same slice.
- When adding, removing, or materially changing a one-click installer under [cli-agents](cli-agents/) or [tool](tool/), MUST update the one-click installer table in [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md) in the same slice.
- [install-statusline.ps1](cli-agents/claude-code/install-statusline.ps1) and [tool/PowerShell/install.ps1](tool/PowerShell/install.ps1) overwrite existing files at their destination without backup.

## Reading Guide

- [UPSTREAM.md](upstream/UPSTREAM.md) when adding, syncing, or installing an upstream project.
- [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md) when working on the CLI reference docs, setting templates, or one-click installers, or when deciding between an agent and a skill.
- [SCRIPTS.md](scripts/SCRIPTS.md) when running or changing a script under `scripts/`.
- [TOOL.md](tool/TOOL.md) when working on the PowerShell profile or tool scripts.
- Skills:
    - `sync-all` to process Dependabot submodule update PRs.
    - `anthropic-skills-sync` to sync the `anthropic-skills` upstream.
    - `cli-doc-sync` to align the CLI reference docs with the official docs.
    - `skills-governance` when creating, modifying, renaming, or removing a project skill.
