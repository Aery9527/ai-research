# AGENTS_zhTW.md — AI 工具 Skills 知識庫

本 repo 彙整 AI 工具使用方式，追蹤 upstream skills，並維護同步與治理流程。

## Repository 守則

### AGENTS 雙語同步規則

- `AGENTS.md` 是英文主版。
- `AGENTS_zhTW.md` 是繁體中文對照版。
- 只要任一檔案有新增、刪除、重新命名或語意變更，兩個語言版本都必須在同一個 change slice 內同步更新。
- Agent 嚴禁先改其中一版、之後再補另一版。

### `scripts/` 文件同步規則

- 當新增、移除、重新命名或明顯改動 [`scripts/`](scripts/) 目錄下的腳本時，必須在同一個 slice 同步更新 [`scripts/SCRIPTS.md`](scripts/SCRIPTS.md)。
- [`scripts/SCRIPTS.md`](scripts/SCRIPTS.md) 是 [`scripts/`](scripts/) 的唯一總索引；新增腳本必須至少補上用途、參數、行為、風險或副作用，以及最小使用範例。
- 若 [`README.md`](README.md) 已列出腳本入口或摘要，agent 必須檢查是否也需要同步更新。

## 專案結構

- [`skill-source/`](skill-source/) — 上游 skill 來源 — 集中存放來自 GitHub 的 skill 函式庫 git submodule，作為本專案持續跟進的上游標的；agents 嚴禁直接修改上游內容。
- [`.claude/skills/`](.claude/skills/) — Project skills — 存放本 repo 的本地維運 skills 與共用協議。
- [`scripts/`](scripts/) — 本地維護腳本 — 存放 repo 維護與自動化腳本；文件索引在 [`scripts/SCRIPTS.md`](scripts/SCRIPTS.md)。

## 本機一鍵安裝腳本

本 repo 另外還有兩支會寫入使用者家目錄（repo 之外）的一鍵 PowerShell 安裝腳本，與 `scripts/` 分開管理：

- [`cli-agents/claude-code/install-statusline.ps1`](cli-agents/claude-code/install-statusline.ps1) — 將 Claude Code 的 status line 與生命週期狀態 hooks 部署到 `~/.claude/`。
- [`tool/PowerShell/install.ps1`](tool/PowerShell/install.ps1) — 將 PowerShell profile 部署到 Documents 底下的 `PowerShell` 資料夾，其餘工具腳本部署到 `$HOME/.config/powershell/`。

兩者都會直接覆寫目標檔案，沒有自動 backup。完整安裝內容說明見 [`README.md`](README.md#一鍵安裝腳本)。
