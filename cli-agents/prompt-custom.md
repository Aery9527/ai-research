# Environment Notes

- Environment record file: `<absolute-recording-repository-path>/prompt-custom.md`.
  Each private `env/*` branch MUST set its own full absolute English path and the matching Chinese path in [prompt-custom_ch.md](prompt-custom_ch.md). MUST NOT put machine-specific paths on `main` or in the public source repository.
  MUST resolve the companion, `ai-research` submodule and root wrappers relative to the configured record file's directory, never the current working directory or installed prompt.
- When the user decides to record a work-environment issue, MUST read both language files and the recording repository's agent instructions. MUST verify the private `env/*` branch and clean repository/index/submodule before changing anything.
  If either path is unset, contains a placeholder, does not identify this same pair, or cannot be read, MUST ask the user before writing.
- MUST fetch public `main` inside the recording repository's `ai-research` submodule and advance its checkout to that fetched commit. MUST NOT merge public Git history into the private parent repository or routinely merge private `main`.
  If the pin changes, MUST review and commit only the `ai-research` gitlink as a separate synchronization commit before editing notes. Pins MUST move forward on public main and retain external-custom installer support. MUST NOT initialize nested submodules; initialized nested submodules or unexpected dirty content MUST stop the workflow for user direction, without automatic cleanup.
  After synchronization, MUST read both language files again.
- MUST record the same case in English in [prompt-custom.md](prompt-custom.md) and Traditional Chinese in [prompt-custom_ch.md](prompt-custom_ch.md). MUST review equivalent facts and instructions, then commit both files together without other changes.
- MUST push the synchronization and record commits to the same private environment branch. Only after a successful push, MUST run the root [Windows wrapper](install-sys-prompt.ps1) or [macOS/Linux wrapper](install-sys-prompt.sh), which deploys the submodule's host template and common user prompt with this repository's English custom.
  Synchronization, review, commit, push or deployment failures MUST stop the workflow and prompt the user; MUST NOT automatically stash, discard changes, resolve conflicts or force-push.
- When the user decides to record project experience, MUST follow the current project's recording conventions. If none exist, MUST suggest an approach and obtain the user's decision before recording.
