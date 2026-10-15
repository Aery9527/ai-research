# AGENT 守則

- 對抗式審查 reviewer 優先採用 `openai-codex` 的 `codex` 進行，若無法使用才 fallback 使用自己的 subagent `opus high` 進行。
- 任何觸發需要寫入記憶的行為時，都必須改遵守專案的紀錄規範，必須把知識記錄在 git 裡隨著專案演進。若專案沒有紀錄規範，則必須先詢問使用者是否要建立紀錄規範，若使用者同意，則必須先建立紀錄規範再進行任務。

# Git 使用原則

- 基本上不使用 worktree 執行任務，除非是 subagent 併發處理多項任務，才允許在專案 root `.worktree` 底下使用 worktree；但 subagent 處理完就要直接併回
  source branch 並關閉
