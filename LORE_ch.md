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
- [install-statusline.ps1](cli-agents/claude-code/install-statusline.ps1) 與 [tool/pwsh/install.ps1](tool/pwsh/install.ps1) 會直接覆寫目標位置的既有檔案，沒有自動 backup。

## Branch 原則

- 修改檔案前，必須確認目前 branch。除 [prompt-custom_ch.md](cli-agents/prompt-custom_ch.md) 的環境專屬紀錄外，其他變更一律必須在 `main` 上進行。
- 將環境專屬案例記錄到 [prompt-custom_ch.md](cli-agents/prompt-custom_ch.md) 前，必須確認目前 branch 符合 `env/*`；嚴禁在 `main` 或其他 branch 記錄此類案例。
- 修改環境紀錄前，必須 fetch 最新的遠端 `main`，再 merge 到目前的 `env/*` branch。同步只允許單向進行：嚴禁將環境專屬變更帶回 `main`，包含 merge、squash、cherry-pick 或複製內容。
- 在 `env/*` 上，只有環境專屬變更僅限於 [prompt-custom_ch.md](cli-agents/prompt-custom_ch.md) 時，才允許 commit 與 push。唯一例外是帶入已存在於 fetch 後遠端 `main` 的 commits，以及僅用於整合這些更新的 merge commits；嚴禁在同步 commit 混入無關修改。commit 前必須檢查已暫存、未暫存變更與未追蹤檔案，push 前必須檢查待推送的 commits；嚴禁僅為通過檢查而略過其他已變更檔案。
- branch 檢查不符、無關的未提交變更阻擋操作、同步衝突，或同步、commit、push、安裝失敗時，必須停下詢問使用者如何處理；嚴禁自動 stash、丟棄變更、解決衝突或 force-push。
- 啟用本機 [branch hooks](scripts/SCRIPTS.md#git-branch-hooks) 後，非 fast-forward 同步必須使用 `git merge --no-commit origin/main`，再執行 `git commit`；自動 merge hook 會拒絕尚無法驗證來源的提交。使用者決定處理方式後，可以解決 [prompt-custom_ch.md](cli-agents/prompt-custom_ch.md) 內的衝突；同步 commit 的非紀錄檔案必須與其 main 父本一致。submodule checkout 漂移、已修改內容與未追蹤內容都必須先檢查，由使用者明確處理後才能提交；嚴禁由 hooks 自動清理。
- 本機 hooks 用於防誤操作，並非伺服器端強制執行：可以停用或略過，也不涵蓋 GitHub 網頁、PR 或 API 更新。main 歷史檢查依賴已知環境 refs，無法可靠辨識任意複製、squash 或 cherry-pick 的來源；詳見 [branch guard 限制](scripts/sd-git-branch-guard.md#限制)。

## 文件結構

- 所有 agent 共用的規則放在 [LORE_ch.md](LORE_ch.md)；host 入口檔只放轉介或僅適用該 host 的規則。
- `LORE`、`AGENTS`、`CLAUDE`、`CODEX` 必須各有無後綴的英文檔與加 `_ch` 後綴的等價繁體中文檔；兩者必須在同一次變更中更新。其他 agent 文件可以加 `_ch` 對應檔，加了之後兩者必須維持等價。`_ch` 檔在對應目標存在時連到 `_ch` 目標。
- 在 `env/*` 上新增於 [prompt-custom_ch.md](cli-agents/prompt-custom_ch.md) 的環境專屬紀錄，不受中英文等價要求限制；在 `main` 維護的共用規則仍必須讓 [prompt-custom.md](cli-agents/prompt-custom.md) 與 [prompt-custom_ch.md](cli-agents/prompt-custom_ch.md) 維持等價。
- agent 文件只放穩定規則；嚴禁寫入任務進度、暫時狀態或進行中的遷移。
- [README.md](README.md) 是繁體中文的人類讀者文件。
- 專案 skill 放在 `.agents/skills/<skill-name>/`；嚴禁直接在 `.claude/skills` 建立 skill 檔案，它是指向 `.agents/skills` 的本機 link。

## 閱讀指引

- [UPSTREAM.md](upstream/UPSTREAM.md)：新增、同步或安裝上游專案時。
- [CLI-AGENTS.md](cli-agents/CLI-AGENTS.md)：處理 CLI 參考文件、設定範本或一鍵安裝腳本，或要決定做 agent 還是 skill 時。
- [SCRIPTS.md](scripts/SCRIPTS.md)：執行或修改 `scripts/` 底下的腳本時。
- [TOOL.md](tool/TOOL.md)：處理 PowerShell profile 或工具腳本時。
- [Git branch guard](scripts/sd-git-branch-guard.md)：修改 branch 防護或 hook 安裝流程時。
- [sync-all](.agents/skills/sync-all/SKILL.md)：處理 Dependabot 開出的 submodule 更新 PR 時。
- [anthropic-skills-sync](.agents/skills/anthropic-skills-sync/SKILL.md)：同步 `anthropic-skills` 上游時。
- [cli-doc-sync](.agents/skills/cli-doc-sync/SKILL.md)：將 CLI 參考文件與官方文件對齊時。
- [skills-governance](.agents/skills/skills-governance/SKILL.md)：建立、修改、重新命名或移除 project skill 時。
