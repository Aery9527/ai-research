# AGENT 守則

- 對抗式審查 reviewer 優先採用 `misty-claude` 的 `claude` 進行，若無法使用才 fallback 使用自己的 subagent `sol high` 進行。

# Git 使用原則

- 基本上不使用 worktree 執行任務，除非是 subagent 併發處理多項任務，才允許在專案 root `.worktree` 底下使用 worktree；但 subagent 處理完就要直接併回
  source branch 並關閉
