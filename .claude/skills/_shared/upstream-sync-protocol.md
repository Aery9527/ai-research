# Upstream Skills Library Sync Protocol

供所有 upstream skill library 的 sync skill 共用。引用方在自己的 `SKILL.md` 填入庫設定後，按照本文件的流程執行。本文件不是 Claude Code skill；它沒有 frontmatter，也不直接出現在 skill 清單。

## Purpose

提供所有 upstream skill library 共用的同步流程，讓每個 sync skill 只需要填入庫設定，不需要重複維護流程本體。

## Caller-Provided Variables

- `LIBRARY_NAME` — 庫的識別名稱。
  - Anthropic 範例：`anthropic-skills`
- `SUBMODULE_PATH` — git submodule 相對路徑。
  - Anthropic 範例：`upstream/anthropic-skills/`
- `SKILL_SOURCE_PATTERN` — skill 來源路徑模式。
  - Anthropic 範例：`skills/<name>/SKILL.md`
- `CO_AUTHOR` — commit 的 `Co-Authored-By` 值。
  - Anthropic 範例：`Claude Sonnet 4.6 <noreply@anthropic.com>`

## Sync Workflow

### Step 1 — Confirm Submodule Status

執行：

```bash
git -C {{SUBMODULE_PATH}} status
```

如果失敗，必須停止並通知使用者先初始化 submodule：

```bash
git submodule update --init {{SUBMODULE_PATH}}
```

### Step 2 — Check Upstream Updates

執行：

```bash
git -C {{SUBMODULE_PATH}} fetch origin
git -C {{SUBMODULE_PATH}} log HEAD..origin/main --oneline
```

- 如果輸出為空，表示沒有更新；必須告知使用者並停止。
- 如果輸出有 commits，繼續 Step 3。

### Step 3 — Identify Changed Skills

執行：

```bash
git -C {{SUBMODULE_PATH}} diff HEAD..origin/main --name-only
git -C {{SUBMODULE_PATH}} diff HEAD..origin/main --name-only --diff-filter=A
```

必須從 `skills/<name>/...` 模式解析出：

- `CHANGED_SKILLS` — 所有有異動的 skill 目錄。
- `NEW_SKILLS` — 全新新增的 skill；它是 `CHANGED_SKILLS` 的子集。

### Step 4 — Pull Updates

執行：

```bash
git -C {{SUBMODULE_PATH}} pull origin main
NEW_HEAD=$(git -C {{SUBMODULE_PATH}} rev-parse --short HEAD)
```

`NEW_HEAD` 供後續 commit message 使用。

### Step 5 — Summarize Skill Changes

對 `CHANGED_SKILLS` 中的每個 skill，依序執行：

1. 讀取 `{{SUBMODULE_PATH}}/skills/<name>/SKILL.md`。
2. 摘要新增或異動 skill 的用途、觸發條件與可能影響。
3. 如果 `<name>` 屬於 `NEW_SKILLS`，必須在 commit message 中列出。

### Step 6 — Update Routing Documents When Needed

如果 `NEW_SKILLS` 非空，或 skill 行為影響 repo 導覽或治理規則，必須同步更新：

1. [`AGENTS.md`](../../../AGENTS.md)，如果 repo 規則或目錄結構受到影響
2. [`AGENTS_zhTW.md`](../../../AGENTS_zhTW.md)，如果 [`AGENTS.md`](../../../AGENTS.md) 有語意變更
3. [`README.md`](../../../README.md)，如果公開導覽或目錄結構受到影響

### Step 7 — Commit

執行：

```bash
git add -A
git commit -m "sync: update {{LIBRARY_NAME}} submodule

Synced from {{LIBRARY_NAME}} @ $NEW_HEAD
Updated skills: <CHANGED_SKILLS 以逗號分隔>

Co-Authored-By: {{CO_AUTHOR}}"
```

## Edge Cases

- 如果 skill 在上游被刪除，必須通知使用者；嚴禁自動刪除本 repo 的對應自管內容。
- 如果新 skill 沒有 `SKILL.md`，必須記錄警告並跳過，嚴禁為它建立本地說明。
- 如果 skill 行為變更影響 [`AGENTS.md`](../../../AGENTS.md) 的 repo 規則，也要同步更新。
- 如果 `git push` 需要認證，必須等待 browser auth 完成後再繼續。
- 如果 submodule 未初始化，Step 1 會失敗；必須提示 `git submodule update --init`。
- 如果 `origin/main` 不存在，必須確認上游 default branch 名稱，例如 `master`，再調整 fetch 指令。

## Verification

Sync 完成後執行：

```powershell
git status
git log --oneline -3
```

驗證重點：

- 沒有未提交異動。
- 最新 commit 符合同步預期。
