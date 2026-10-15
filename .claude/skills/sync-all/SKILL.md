---
name: sync-all
description: >-
  Use when Dependabot has opened PRs for submodule updates and you want to sync
  all pending upstream skill libraries in one step. Reads open Dependabot PRs,
  matches them to the local sync-skill map, runs them
  in sequence, then closes the PRs. Triggers on: "sync all", "update all
  skills", "process Dependabot PRs", "run sync-all".
---

# Sync-All

統一入口 skill，自動發現所有待 sync 的 submodule 並依序 orchestrate 對應的 sync skill。

## 前置條件

確認 `gh` CLI 已登入：

```bash
gh auth status
```

若輸出包含 `You are not logged into any GitHub hosts`，提示使用者執行：

```bash
gh auth login
```

停止並等待使用者重試。

## Step 1 — 列出 open Dependabot PRs

```bash
gh pr list \
  --author "app/dependabot" \
  --state open \
  --json number,headRefName,title \
  --jq '.[] | select(.headRefName | startswith("dependabot/submodules/"))'
```

- 若結果為空 → 告知使用者「✅ 無待處理的上游更新」並停止，不報錯
- 若有結果 → 繼續，記錄每個 PR 的 `number` 與 `headRefName`

## Step 2 — 解析 submodule 名稱

從 `headRefName` 中移除前綴 `dependabot/submodules/` 得到 submodule path（自 submodules 搬遷至 `skill-source/` 後，路徑前綴含 `skill-source/`）：

```
dependabot/submodules/skill-source/anthropic-skills  →  skill-source/anthropic-skills
```

## Step 3 — 使用固定 sync skill 對應表

使用 repo 內固定映射表，不要從 frontmatter 動態發現：

```
submodule path                    →  skill 目錄名稱
"skill-source/anthropic-skills"   →  "anthropic-skills-sync"
```

## Step 4 — 比對並準備執行清單

對 Step 2 的每個 submodule：
- 若在映射表中找到對應 skill → 加入執行清單（記錄 skill name 與 PR number）
- 若找不到 → 印警告 `⚠️ 找不到 <submodule-name> 的對應 sync skill，跳過` 並繼續

若執行清單為空 → 告知使用者「⚠️ 所有 PR 都找不到對應 sync skill，請手動檢查」並停止。

## Step 5 — 依序 invoke sync skill

對執行清單中每個項目，使用 Skill tool invoke 對應的 sync skill。
每個 sync skill 負責：pull submodule → AI 生成繁中摘要 → commit → push to main。
等待每個 sync skill 完成後再進行下一個。

## Step 6 — 關閉 Dependabot PR

每個成功 sync 的 submodule，關閉對應 PR：

```bash
gh pr close <PR_NUMBER> \
  --comment "Synced via sync-all skill. Submodule updated."
```

若 `gh pr close` 失敗（PR 已關閉或已被 merge）：
- 印出 `ℹ️ PR #<N> 已關閉，跳過`
- 繼續處理其他 PR，不視為錯誤

## 完成

印出摘要：

```
✅ sync-all 完成
   已同步：<skill-name1>, <skill-name2>
   已關閉 PR：#<N1>, #<N2>
```
