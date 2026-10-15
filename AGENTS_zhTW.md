# AGENTS.md

- 本 repo 研究 AI CLI 工具：以 git submodule 追蹤上游 skill、plugin 與 MCP server，並維護研究文件、使用者級別設定範本、安裝腳本，以及本地同步與治理流程。
- 本 repo 不是可發佈的 plugin；[.claude/skills](.claude/skills/) 存放的 project skills 只用於維護本 repo。

## 目錄索引

- [upstream](upstream/) — 上游 git submodule；嚴禁直接修改其內容；總覽在 [UPSTREAM.md](upstream/UPSTREAM.md)
- [cli-agents](cli-agents/) — AI CLI 參考文件、使用者級別設定範本，以及寫入使用者家目錄的一鍵安裝腳本；總覽在 [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md)
- [scripts](scripts/) — repo 維護與自動化腳本；[SCRIPTS.md](scripts/SCRIPTS.md) 是唯一索引
- [tool](tool/) — 本機工具文件與 PowerShell profile 腳本；總覽在 [TOOL.md](tool/TOOL.md)
- [.claude/skills](.claude/skills/) — project skills 與共用的上游同步協議
- [.github/dependabot.yml](.github/dependabot.yml) — 每日檢查上游 submodule 更新

## 注意事項

- `AGENTS.md` 是英文主版，`AGENTS_zhTW.md` 是繁體中文對照版；任一檔案有變更時，必須在同一個 change slice 內同步更新兩版，嚴禁先改一版、之後再補另一版。
- 新增、移除、重新命名或明顯改動 [scripts](scripts/) 底下的腳本時，必須在同一個 slice 更新 [SCRIPTS.md](scripts/SCRIPTS.md)；新增的腳本至少必須記錄用途、參數、行為、風險或副作用，以及最小使用範例。
- 腳本變更使 [README.md](README.md) 列出的腳本入口或摘要過期時，必須在同一個 slice 更新 README.md。
- 新增、移除或明顯改動 [cli-agents](cli-agents/) 或 [tool](tool/) 底下的一鍵安裝腳本時，必須在同一個 slice 更新 [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md) 的一鍵安裝腳本表。
- [install-statusline.ps1](cli-agents/claude-code/install-statusline.ps1) 與 [tool/PowerShell/install.ps1](tool/PowerShell/install.ps1) 會直接覆寫目標位置的既有檔案，沒有自動 backup。

## 閱讀指引

- [UPSTREAM.md](upstream/UPSTREAM.md)：新增、同步或安裝上游專案時。
- [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md)：處理 CLI 參考文件、設定範本或一鍵安裝腳本，或要決定做 agent 還是 skill 時。
- [SCRIPTS.md](scripts/SCRIPTS.md)：執行或修改 `scripts/` 底下的腳本時。
- [TOOL.md](tool/TOOL.md)：處理 PowerShell profile 或工具腳本時。
- Skills：
    - `sync-all`：處理 Dependabot 開出的 submodule 更新 PR。
    - `anthropic-skills-sync`：同步 `anthropic-skills` 上游。
    - `cli-doc-sync`：將 CLI 參考文件與官方文件對齊。
    - `skills-governance`：建立、修改、重新命名或移除 project skill 時。
