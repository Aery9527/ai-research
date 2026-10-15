# AGENTS.md — AI Tool Skills Knowledge Base

Purpose: track upstream AI tool skills and maintain local sync and governance workflows.

## Repository Governance

### Bilingual AGENTS Rule

- `AGENTS.md` is the English primary version.
- `AGENTS_zhTW.md` is the Traditional Chinese mirror.
- Any addition, deletion, rename, or semantic change to either file MUST update both language versions in the same change slice.
- The agent MUST NOT leave one language temporarily stale with a plan to sync it later.

### `scripts/` Documentation Sync Rule

- When adding, removing, renaming, or materially changing scripts under [`scripts/`](scripts/), the agent MUST update [`scripts/SCRIPTS.md`](scripts/SCRIPTS.md) in the same slice.
- [`scripts/SCRIPTS.md`](scripts/SCRIPTS.md) is the single index for [`scripts/`](scripts/); new scripts MUST document at least purpose, arguments, behavior, risks or side effects, and a minimal usage example.
- If [`README.md`](README.md) already lists script entries or summaries, the agent MUST check whether it also needs to be updated.

## Project Structure

- [`upstream/`](upstream/) — Upstream sources — Contains upstream projects from GitHub as git submodules (skills, plugins, MCP servers, or other tools) that remain the upstream targets this project tracks; agents MUST NOT modify upstream content directly.
- [`.claude/skills/`](.claude/skills/) — Project skills — Contains local maintenance skills and shared protocols for this repo.
- [`scripts/`](scripts/) — Local maintenance scripts — Contains repo maintenance and automation scripts; the document index lives in [`scripts/SCRIPTS.md`](scripts/SCRIPTS.md).

## Local Install Scripts

This repo also ships one-click PowerShell installers that write to the user's home directory (outside the repo), separate from `scripts/`. They include these two:

- [`cli-agents/claude-code/install-statusline.ps1`](cli-agents/claude-code/install-statusline.ps1) — deploys the Claude Code status line and lifecycle-state hooks to `~/.claude/`.
- [`tool/PowerShell/install.ps1`](tool/PowerShell/install.ps1) — deploys the PowerShell profile to the Documents `PowerShell` folder and the remaining tool scripts to `$HOME/.config/powershell/`.

Both overwrite existing files at their destination without backup. See [`README.md`](README.md#一鍵安裝腳本) for the full breakdown of what each script installs.
