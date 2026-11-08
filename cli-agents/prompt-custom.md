# Environment Notes

- Environment record file: `<absolute-repository-path>/cli-agents/prompt-custom.md`.
  On each `env/*` branch, MUST replace the placeholder with that environment's full absolute path and set the corresponding Chinese path in [prompt-custom_ch.md](prompt-custom_ch.md). MUST NOT put machine-specific paths on `main`.
  MUST resolve companion files and installers relative to the configured record file's directory, not the current working directory or the installed user prompt.
- When the user decides to record a work-environment issue, MUST use the configured record file and its Chinese companion in the same directory.
  If a path is unset, still contains a placeholder, the configured paths do not identify this same pair, or either file cannot be read, MUST ask the user before writing.
  MUST first read both files and the recording repository's agent instructions, verify the current branch is `env/*`, and fetch and merge remote `main` according to that repository's rules.
  After synchronization, MUST read both files again before editing.
- MUST record the same case in English in [prompt-custom.md](prompt-custom.md) and in Traditional Chinese in [prompt-custom_ch.md](prompt-custom_ch.md), preserving equivalent facts and instructions. MUST review both versions before committing them together.
- After recording, MUST commit and push both files on the same environment branch. Only after a successful push, MUST run that repository's [prompt installer](install-sys-prompt.ps1) on Windows or [Bash installer](install-sys-prompt.sh) on macOS/Linux to redeploy the English prompt. If synchronization, commit, push or installation is blocked or fails, MUST stop and ask the user; MUST NOT automatically stash, discard changes, resolve conflicts or force-push.
- When the user decides to record project experience, MUST follow the current project's recording conventions. If none exist, MUST suggest an approach and obtain the user's decision before recording.
