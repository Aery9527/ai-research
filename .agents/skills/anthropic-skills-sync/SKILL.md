---
name: anthropic-skills-sync
description: >-
  Use this skill when the user asks to sync, update, refresh, or check for
  updates to the anthropic-skills library. Triggers when user says "sync
  skills", "update skills", "check for upstream changes", "pull latest skills
  from Anthropic", or any variation of wanting to keep the local
  anthropic-skills submodule in sync with the upstream repository.
---

# Anthropic Skills Sync

## Library Configuration

- `LIBRARY_NAME` -> `anthropic-skills`
- `UPSTREAM_URL` -> [anthropics/skills.git](https://github.com/anthropics/skills.git)
- `SUBMODULE_PATH` -> `upstream/anthropic-skills/`
- `SKILL_SOURCE_PATTERN` -> `skills/<name>/SKILL.md`
- `CO_AUTHOR` -> `Claude Sonnet 4.6 <noreply@anthropic.com>`

## Workflow

Read [upstream-sync-protocol.md](../_shared/upstream-sync-protocol.md), substitute the library configuration above into the protocol variables, and execute the shared sync workflow in order.
