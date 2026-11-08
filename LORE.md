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
- [install-statusline.ps1](cli-agents/claude-code/install-statusline.ps1) and [tool/pwsh/install.ps1](tool/pwsh/install.ps1) overwrite existing files at their destination without backup.

## Branch Rules

- Before modifying files, MUST check the current branch. All changes other than environment-specific records in [prompt-custom.md](cli-agents/prompt-custom.md) and [prompt-custom_ch.md](cli-agents/prompt-custom_ch.md) MUST be made on `main`.
- Before recording an environment-specific case in [prompt-custom.md](cli-agents/prompt-custom.md) and [prompt-custom_ch.md](cli-agents/prompt-custom_ch.md), MUST verify that the current branch matches `env/*`; MUST NOT record such cases on `main` or any other branch.
- Before modifying an environment record, MUST fetch the latest remote `main` and merge it into the current `env/*` branch. This synchronization is one-way: MUST NOT bring environment-specific changes back into `main`, including by merge, squash, cherry-pick or copying content.
- On `env/*`, MUST commit and push ordinary environment records only when both files change together and the changes are limited to [prompt-custom.md](cli-agents/prompt-custom.md) and [prompt-custom_ch.md](cli-agents/prompt-custom_ch.md). The only exception is importing commits already on the fetched remote `main` and merge commits that solely integrate those updates; MUST NOT include unrelated edits in synchronization commits. MUST check staged changes, unstaged changes and untracked files before committing, and the commits to be pushed before pushing; MUST NOT omit other changed files merely to pass this check.
- If a branch check fails, unrelated uncommitted changes block the operation, synchronization conflicts, or synchronization, commit, push or installation fails, MUST stop and ask the user how to proceed; MUST NOT automatically stash, discard changes, resolve conflicts or force-push.
- With the local [branch hooks](scripts/SCRIPTS.md#git-branch-hooks) enabled, non-fast-forward synchronization MUST use `git merge --no-commit origin/main` followed by `git commit`; the automatic merge hook rejects commits before their source can be verified. Users may resolve conflicts in [prompt-custom.md](cli-agents/prompt-custom.md) and [prompt-custom_ch.md](cli-agents/prompt-custom_ch.md) after deciding how to proceed; non-record files in a synchronization commit MUST match its main parent. Submodule checkout drift, modified content and untracked content MUST be inspected and explicitly handled by the user before committing; hooks MUST NOT clean them automatically.
- Local hooks are guardrails, not server-side enforcement: they can be disabled or bypassed and do not cover GitHub web, PR or API updates. Main-history checks depend on known environment refs and cannot reliably identify arbitrary copying, squash or cherry-pick provenance; see [branch guard limits](scripts/sd-git-branch-guard.md#限制).

### General changes and branch restoration

- This workflow applies to general repository changes, not environment records. The agent MUST perform the branch switches; hooks only validate operations and do not switch branches.

1. Before starting, MUST remember the starting branch in task context. If it is `env/*`, MUST use it as the return branch. Otherwise, if no return environment branch is known or specified, MUST ask the user whether to return to an environment branch and which one; MUST NOT guess or write task-specific branch state into agent instruction files.
2. Before each branch switch, MUST verify that the working tree and index are clean, including untracked files. Before editing, MUST switch to `main` if necessary, fetch `origin/main`, update `main` with fast-forward only, and verify that `main` equals `origin/main`. After updating `main` and before editing, MUST recheck cleanliness with `git status --porcelain=v1 --untracked-files=all --ignore-submodules=none`, including submodule checkout drift; a dirty result MUST stop the workflow and prompt the user, without automatic `git submodule update`. A planned clean switch does not require another confirmation; an unexpected branch, blocked switch, local commits ahead of `origin/main`, or divergence MUST stop the workflow and prompt the user.
3. MUST complete the changes, review, commit and push on `main`; before pushing, MUST inspect `origin/main..main` and verify that it contains only reviewed commits for this task. MUST NOT deploy the user prompt from `main` during this workflow. If the user chooses not to return to an environment branch, MUST finish on `main`, skip steps 4–5 and report that prompt deployment was skipped.
4. With a clean working tree, MUST switch back to the saved environment branch, fetch the latest remote `main`, and merge `origin/main` under the existing hook rules. If a merge commit is needed, MUST validate and commit that synchronization; fast-forward or already-up-to-date results MUST NOT produce an empty commit. Conflicts or other failures MUST stop the workflow and prompt the user, without automatic stash, discard, conflict resolution or force-push.
5. MUST push the updated environment branch, then reinstall the English prompt from that branch using the repository's [Windows prompt installer](cli-agents/install-sys-prompt.ps1) or [macOS/Linux prompt installer](cli-agents/install-sys-prompt.sh). MUST finish on the saved environment branch, unless the user explicitly requests a different final branch.

## Document Structure

- Rules shared by every agent live in [LORE.md](LORE.md); host entry files hold only routing or rules for that host alone.
- `LORE`, `AGENTS`, `CLAUDE`, and `CODEX` MUST each have an English file without suffix and an equivalent Traditional Chinese file with the `_ch` suffix; MUST update both in the same change. Any other agent document MAY add a `_ch` counterpart, and the pair MUST then stay equivalent. A `_ch` file links to `_ch` targets when they exist.
- Environment-specific cases and configured record paths MUST be maintained as an equivalent English/Traditional Chinese pair on `env/*`; each prompt points to its own language file. Hooks check paired file changes and regular-file existence, but MUST NOT be treated as proof of translation equivalence. Synchronization merges may change either or neither record file; old single-file environment history requires user-directed migration before it can pass the paired checks.
- Agent documents hold only stable rules; MUST NOT write task progress, temporary state, or ongoing migrations into them.
- [README.md](README.md) is a Traditional Chinese human-reader document.
- Project skills live in `.agents/skills/<skill-name>/`; MUST NOT create skill files directly under `.claude/skills`, which is a local link to `.agents/skills`.

## Reading Guide

- [UPSTREAM.md](upstream/UPSTREAM.md) when adding, syncing, or installing an upstream project.
- [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md) when working on the CLI reference docs, setting templates, or one-click installers, or when deciding between an agent and a skill.
- [SCRIPTS.md](scripts/SCRIPTS.md) when running or changing a script under `scripts/`.
- [TOOL.md](tool/TOOL.md) when working on the PowerShell profile or tool scripts.
- [Git branch guard](scripts/sd-git-branch-guard.md) when changing branch enforcement or hook installation.
- [sync-all](.agents/skills/sync-all/SKILL.md) when processing Dependabot submodule update PRs.
- [anthropic-skills-sync](.agents/skills/anthropic-skills-sync/SKILL.md) when syncing the `anthropic-skills` upstream.
- [cli-doc-sync](.agents/skills/cli-doc-sync/SKILL.md) when aligning CLI reference docs with the official docs.
- [skills-governance](.agents/skills/skills-governance/SKILL.md) when creating, modifying, renaming, or removing a project skill.
