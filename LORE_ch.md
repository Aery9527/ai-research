# LORE

- 本 repo 研究 AI CLI 工具：以 git submodule 追蹤上游 skill、plugin 與 MCP server，並維護研究文件、使用者級別設定範本、安裝腳本，以及本地同步與治理流程。
- 本 repo 不是可發佈的 plugin；[.agents/skills](.agents/skills/) 存放的 project skills 只用於維護本 repo。

## 目錄索引

- [upstream](upstream/) — 上游 git submodule；嚴禁直接修改其內容；總覽在 [UPSTREAM.md](upstream/UPSTREAM.md)
- [cli-agents](cli-agents/) — AI CLI 參考文件、使用者級別設定範本，以及寫入使用者家目錄的一鍵安裝腳本；總覽在 [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md)
- [scripts](scripts/) — repo 維護與自動化腳本；[SCRIPTS.md](scripts/SCRIPTS.md) 是唯一索引
- [tool](tool/) — 本機工具文件與 PowerShell profile 腳本；總覽在 [TOOL.md](tool/TOOL.md)
- [ide](ide/) — IDE 設定筆記
- [.agents/skills](.agents/skills/) — project skills 與共用的上游同步協議
- [.github/dependabot.yml](.github/dependabot.yml) — 每日檢查上游 submodule 更新

## 維護規則

- 新增、移除、重新命名或明顯改動 [scripts](scripts/) 底下的腳本時，必須在同一個 slice 更新 [SCRIPTS.md](scripts/SCRIPTS.md)；新增的腳本至少必須記錄用途、參數、行為、風險或副作用，以及最小使用範例。
- 腳本變更使 [README.md](README.md) 列出的腳本入口或摘要過期時，必須在同一個 slice 更新 README.md。
- 新增、移除或明顯改動 [cli-agents](cli-agents/) 或 [tool](tool/) 底下的一鍵安裝腳本時，必須在同一個 slice 更新 [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md) 的一鍵安裝腳本表。
- [install-statusline.ps1](cli-agents/claude-code/install-statusline.ps1) 與 [tool/PowerShell/install.ps1](tool/PowerShell/install.ps1) 會直接覆寫目標位置的既有檔案，沒有自動 backup。

## 文件結構

- 所有 agent 共用的規則放在 [LORE_ch.md](LORE_ch.md)；host 入口檔只放轉介或僅適用該 host 的規則。
- `LORE`、`AGENTS`、`CLAUDE`、`CODEX` 必須各有無後綴的英文檔與加 `_ch` 後綴的等價繁體中文檔；兩者必須在同一次變更中更新。其他 agent 文件可以加 `_ch` 對應檔，加了之後兩者必須維持等價。`_ch` 檔在對應目標存在時連到 `_ch` 目標。
- agent 文件只放穩定規則；嚴禁寫入任務進度、暫時狀態或進行中的遷移。
- [README.md](README.md) 是繁體中文的人類讀者文件。
- 專案 skill 放在 `.agents/skills/<skill-name>/`；嚴禁直接在 `.claude/skills` 建立 skill 檔案，它是指向 `.agents/skills` 的本機 link。

## 閱讀指引

- [UPSTREAM.md](upstream/UPSTREAM.md)：新增、同步或安裝上游專案時。
- [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md)：處理 CLI 參考文件、設定範本或一鍵安裝腳本，或要決定做 agent 還是 skill 時。
- [SCRIPTS.md](scripts/SCRIPTS.md)：執行或修改 `scripts/` 底下的腳本時。
- [TOOL.md](tool/TOOL.md)：處理 PowerShell profile 或工具腳本時。
- [sync-all](.agents/skills/sync-all/SKILL.md)：處理 Dependabot 開出的 submodule 更新 PR 時。
- [anthropic-skills-sync](.agents/skills/anthropic-skills-sync/SKILL.md)：同步 `anthropic-skills` 上游時。
- [cli-doc-sync](.agents/skills/cli-doc-sync/SKILL.md)：將 CLI 參考文件與官方文件對齊時。
- [skills-governance](.agents/skills/skills-governance/SKILL.md)：建立、修改、重新命名或移除 project skill 時。
