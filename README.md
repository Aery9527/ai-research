# ai-research

> AI 工具研究 × Skills 知識庫：彙整 Claude Code、GitHub Copilot、Codex 等 AI 工具的使用方式。

```mermaid
flowchart LR
    U(["👤 使用者"])

    subgraph nav ["導覽層"]
        A["📋 AGENTS.md / AGENTS_zhTW.md\nrepo 規則"]
        B["📖 README.md\n快速定位"]
    end

    subgraph runtime ["Project skill 層 (.claude/skills/)"]
        C1["🔄 sync / CLI docs / governance"]
    end

    subgraph upstream ["上游來源層 (N 個 submodule)"]
        S["📦 anthropic-skills\n📦 webwright\n📦 …"]
        P["🔄 _shared/upstream-sync-protocol"]
    end

    U --> nav --> runtime
    S -->|"submodule source"| runtime
    P -.->|"sync 協議"| runtime
```

## Quick Navigation

- [首次初始化 submodule](#首次初始化-submodule)
- [同步上游更新](#同步上游更新)
- [Skills 系統](#skills-系統)
  - [.claude-plugin 檔案說明](#claude-plugin-檔案說明)
  - [anthropic-skills](#anthropic-skills)
  - [webwright](#webwright)
  - [codex-plugin-cc](#codex-plugin-cc)
  - [playwright-mcp](#playwright-mcp)
- [AI 工具文件](#ai-工具文件)
- [Agent 與 Skill 差異](#agent-與-skill-差異)
- [腳本文件](#腳本文件)
- [一鍵安裝腳本](#一鍵安裝腳本)
- [Project Skills](#project-skills)
- [目錄結構](#目錄結構)

[Back to top](#quick-navigation)

---

## 首次初始化 submodule

```powershell
git submodule update --init --recursive
```

[Back to top](#quick-navigation)

---

## 同步上游更新

[GitHub Dependabot](.github/dependabot.yml) 每日自動偵測上游 submodule 變更並開 PR。收到通知 email 後，invoke `sync-all` 同步：

> Dependabot 開 PR → email 通知 → invoke `sync-all` → pull + AI 摘要 + commit + push + 關閉 PR

`sync-all` 只處理 [對應表](.claude/skills/sync-all/SKILL.md) 內有 sync skill 的上游，目前只有 `anthropic-skills`；`webwright`、`codex-plugin-cc`、`playwright-mcp` 沒有對應 sync skill，`sync-all` 會跳過它們，需要另外處理。

[Back to top](#quick-navigation)

---

## Skills 系統

本 repo 以 submodule 追蹤上游專案（skill、plugin、MCP server 等），並維護本 repo 處理任務時使用的 project skills：

| 目錄 | 類型 | 來源 | 用途 |
|------|------|------|------|
| `upstream/anthropic-skills/` | skill | [Anthropic 上游](https://github.com/anthropics/skills) | 創意設計、前端工程、AI 工程、Office 文件、技術寫作 |
| `upstream/webwright/` | skill | [Microsoft Webwright 上游](https://github.com/microsoft/Webwright) | 瀏覽器自動化：以單一 bash command 驅動本地 Playwright workspace，附截圖與 action log 自我驗證 |
| `upstream/codex-plugin-cc/` | Claude Code plugin | [OpenAI codex-plugin-cc 上游](https://github.com/openai/codex-plugin-cc) | 在 Claude Code 內呼叫 Codex 做 code review 或委派任務 |
| `upstream/playwright-mcp/` | MCP server | [Microsoft playwright-mcp 上游](https://github.com/microsoft/playwright-mcp) | 瀏覽器自動化：以 Playwright accessibility snapshot 操作網頁 |
| `.claude/skills/` | project skill | 本地 | 同步上游、同步 CLI 文件、治理 workflow、共用維運協議 |

要確認 upstream skill 的用途時，直接讀取 [`upstream/anthropic-skills/skills/`](upstream/anthropic-skills/skills/) 下的原始 `SKILL.md`；真正執行時，使用已安裝的 upstream skill。

### 共用基礎設施

[`.claude/skills/_shared/upstream-sync-protocol.md`](.claude/skills/_shared/upstream-sync-protocol.md) — 各 upstream sync skill 共用的通用 sync 流程協議。新增第三、四個 submodule 時，sync skill 只需引用這份文件 + 填入庫設定。

### .claude-plugin 檔案說明

Claude Code plugin 系統在 `.claude-plugin/` 目錄下有兩種設定檔，職責不同：

| 檔案 | 層次 | 定義的是什麼 |
|------|------|------------|
| `marketplace.json` | Marketplace 層 | 一個目錄清單：列出要發行哪些 plugins、各自來源與設定 |
| `plugin.json` | Plugin 層 | 單個 plugin 的身份：`name`, `version`, `author`, `keywords`… |

**為什麼 `anthropic-skills/` 只有 `marketplace.json`？**

`anthropic-skills` 純粹是一個 **marketplace**，打包了 `document-skills`、`example-skills`、`claude-api` 等多個 plugin。它的 `marketplace.json` 對每個 plugin 都設了 `"strict": false`，意思是由 marketplace 完全控制 plugin 配置，各 plugin 不需要自己的 `plugin.json`。

> `strict: false` = marketplace entry 是完整定義，plugin 內不需要自備 `plugin.json`。  
> 預設 `strict: true` = plugin 自己的 `plugin.json` 才是權威來源。

---

### anthropic-skills

目前 `anthropic-skills` 主要透過 Claude Code / GitHub Copilot CLI 的 plugin marketplace 使用；本 repo 尚未替它提供 Codex marketplace 或 `.codex-plugin` 封裝。

| 維度 | Claude Code | GitHub Copilot CLI | Codex |
|------|------|------|------|
| 說明 | 使用 `anthropics/skills` 作為 marketplace source，marketplace 名稱是 `anthropic-agent-skills`。 | 使用同一份 `.claude-plugin/marketplace.json`，透過 `copilot plugin` 註冊 marketplace 並安裝 plugin。 | 目前不適用；`upstream/anthropic-skills/` 沒有 Codex 用的 `.agents/plugins/marketplace.json` 或 `.codex-plugin/plugin.json`。 |
| 安裝 | `/plugin marketplace add anthropics/skills`<br>`/plugin install document-skills@anthropic-agent-skills`<br>`/plugin install example-skills@anthropic-agent-skills`<br>`/plugin install claude-api@anthropic-agent-skills`<br>`/reload-plugins` | `copilot plugin marketplace add anthropics/skills`<br>`copilot plugin install document-skills@anthropic-agent-skills`<br>`copilot plugin install example-skills@anthropic-agent-skills`<br>`copilot plugin install claude-api@anthropic-agent-skills`<br>`copilot plugin list` | 需先另建 Codex 封裝後才能安裝。 |
| 更新 | `/plugin marketplace update anthropic-agent-skills`<br>`/reload-plugins`<br>或在 `/plugin` 的 Marketplaces tab 對 `anthropic-agent-skills` 啟用 auto-update。 | `copilot plugin update document-skills@anthropic-agent-skills`<br>`copilot plugin update example-skills@anthropic-agent-skills`<br>`copilot plugin update claude-api@anthropic-agent-skills` | 不適用。 |
| 移除 | `/plugin uninstall document-skills@anthropic-agent-skills`<br>`/plugin uninstall example-skills@anthropic-agent-skills`<br>`/plugin uninstall claude-api@anthropic-agent-skills`<br>`/plugin marketplace remove anthropic-agent-skills` | `copilot plugin uninstall document-skills@anthropic-agent-skills`<br>`copilot plugin uninstall example-skills@anthropic-agent-skills`<br>`copilot plugin uninstall claude-api@anthropic-agent-skills`<br>`copilot plugin marketplace remove anthropic-agent-skills` | 不適用。 |

詳細設定見 [`upstream/anthropic-skills/.claude-plugin/marketplace.json`](upstream/anthropic-skills/.claude-plugin/marketplace.json)。

> **已知 bug**：若同一批 skills 同時由 project top-level entries 與 plugin namespace 暴露，context 與 slash command picker 仍可能重複。當前結構設計就是為了避免這個情況。相關 issue：[anthropics/claude-code#29520](https://github.com/anthropics/claude-code/issues/29520)、[anthropics/skills#189](https://github.com/anthropics/skills/issues/189)

### webwright

`webwright` 是 Microsoft Research 出品的瀏覽器代理 skill：把宿主 agent 變成 SOTA browser agent，透過一次一個 bash command 驅動本地 Playwright workspace，並把每步截圖與 action log 保存在 `final_runs/run_<id>/`，再以視覺方式自我驗證結果。上游同時提供 Claude Code 與 Codex 的 plugin manifest，[`upstream/webwright/skills/webwright/`](upstream/webwright/skills/webwright/) 內容兩端共用。

| 維度 | Claude Code | GitHub Copilot CLI | Codex |
|------|------|------|------|
| 說明 | Marketplace source 是 `microsoft/Webwright`，marketplace 與 plugin 名稱皆為 `webwright`。 | Copilot CLI 讀取相同 Claude 風格 marketplace，透過 `copilot plugin` 註冊與安裝。 | 優先用 Codex 的 user-level skill discovery，把 Webwright skill junction 到 `~/.agents/skills/webwright`。 |
| 安裝 | `/plugin marketplace add microsoft/Webwright`<br>`/plugin install webwright@webwright`<br>`/reload-plugins` | `copilot plugin marketplace add microsoft/Webwright`<br>`copilot plugin install webwright@webwright`<br>`copilot plugin list` | 建立 `~/.agents/skills/webwright` junction，並安裝 Webwright runtime；完整 PowerShell 流程見下方。 |
| 更新 | `/plugin marketplace update webwright`<br>`/reload-plugins` | `copilot plugin update webwright@webwright` | 更新 submodule 後重新開 Codex；junction 會指向新的 submodule 內容。 |
| 移除 | `/plugin uninstall webwright@webwright`<br>`/plugin marketplace remove webwright` | `copilot plugin uninstall webwright@webwright`<br>`copilot plugin marketplace remove webwright` | 刪除 `~/.agents/skills/webwright` junction；可選擇保留或移除 Python runtime。 |

Codex 建議使用下列 skill-only 安裝流程：

```powershell
git submodule update --init --recursive

$skillTarget = Resolve-Path "upstream\webwright\skills\webwright"
$skillLink = Join-Path $env:USERPROFILE ".agents\skills\webwright"
New-Item -ItemType Directory -Force -Path (Split-Path $skillLink) | Out-Null
if (-not (Test-Path $skillLink)) {
    New-Item -ItemType Junction -Path $skillLink -Target $skillTarget.Path | Out-Null
}

python -m pip install -e "upstream\webwright"
python -m playwright install firefox
```

安裝後用這些指令確認狀態：

```text
codex
/skills
```

```powershell
python -m playwright --version
```

重新開 Codex 後，可用 `$webwright` 明確呼叫，或讓 Codex 依 [`upstream/webwright/skills/webwright/SKILL.md`](upstream/webwright/skills/webwright/SKILL.md) 的 description 自動觸發。若要使用原生 Webwright CLI harness，再額外執行 `python -m playwright install chromium` 並依 backend 設定 API key；`python -m webwright.run.cli doctor` 檢查的是原生 harness，不是 Codex skill-only 路徑。

> [Webwright 官方 README](https://github.com/microsoft/Webwright) 仍列出 `codex plugin marketplace add microsoft/Webwright` → `/plugins` 的 plugin 安裝流程；但目前已有 [microsoft/Webwright issue #37](https://github.com/microsoft/Webwright/issues/37) 回報該 Git marketplace 缺少 Codex 會列舉的 `.agents/plugins/marketplace.json` index，導致 `webwright` 在 Codex plugin browser 內不可見。等上游補齊 marketplace index 後，再改回官方 plugin 流程。

詳細設定見 [`upstream/webwright/.claude-plugin/marketplace.json`](upstream/webwright/.claude-plugin/marketplace.json)、[`upstream/webwright/.claude-plugin/plugin.json`](upstream/webwright/.claude-plugin/plugin.json) 與 [`upstream/webwright/.codex-plugin/plugin.json`](upstream/webwright/.codex-plugin/plugin.json)。

[Back to top](#quick-navigation)

---

### codex-plugin-cc

`codex-plugin-cc` 是 OpenAI 出品的 Claude Code plugin：在 Claude Code 內呼叫 Codex 做 code review（`/codex:review`、`/codex:adversarial-review`）或委派任務（`/codex:rescue`、`/codex:transfer`），並以 `/codex:status`、`/codex:result`、`/codex:cancel` 管理背景工作。上游只提供 Claude Code 用的 `.claude-plugin` manifest；使用前需要 Node.js 18.18 以上，以及 ChatGPT 訂閱或 OpenAI API key。

| 維度 | Claude Code |
|------|------|
| 說明 | Marketplace source 是 `openai/codex-plugin-cc`，marketplace 名稱是 `openai-codex`，plugin 名稱是 `codex`。 |
| 安裝 | `/plugin marketplace add openai/codex-plugin-cc`<br>`/plugin install codex@openai-codex`<br>`/reload-plugins`<br>`/codex:setup` |
| 更新 | `/plugin marketplace update openai-codex`<br>`/reload-plugins` |
| 移除 | `/plugin uninstall codex@openai-codex`<br>`/plugin marketplace remove openai-codex` |

詳細設定見 [`upstream/codex-plugin-cc/.claude-plugin/marketplace.json`](upstream/codex-plugin-cc/.claude-plugin/marketplace.json) 與 [`upstream/codex-plugin-cc/plugins/codex/.claude-plugin/plugin.json`](upstream/codex-plugin-cc/plugins/codex/.claude-plugin/plugin.json)。

[Back to top](#quick-navigation)

---

### playwright-mcp

`playwright-mcp` 是 Microsoft 出品的 MCP server（npm 套件 `@playwright/mcp`）：透過 Playwright 的 accessibility snapshot 讓 LLM 操作網頁，不需要截圖或視覺模型。上游沒有 plugin manifest 或 skill；Claude Code 官方 marketplace 的 `playwright` plugin 只是以 `npx @playwright/mcp@latest` 啟動此 MCP server 的包裝。使用前需要 Node.js 18 以上。

| 維度 | Claude Code | GitHub Copilot CLI | Codex |
|------|------|------|------|
| 說明 | 可安裝官方 marketplace 的 `playwright` plugin，或直接以 `claude mcp add` 註冊 MCP server。 | 以 `/mcp add` 互動式註冊，或編輯 `~/.copilot/mcp-config.json`。 | 以 `codex mcp add` 註冊，或編輯 `~/.codex/config.toml` 的 `[mcp_servers.playwright]`。 |
| 安裝 | `/plugin install playwright@claude-plugins-official`<br>`/reload-plugins`<br>或：<br>`claude mcp add playwright npx @playwright/mcp@latest` | `/mcp add` | `codex mcp add playwright npx "@playwright/mcp@latest"` |
| 更新 | 設定使用 `@playwright/mcp@latest`，由 `npx` 在啟動 MCP server 時解析版本。 | 同左。 | 同左。 |
| 移除 | `/plugin uninstall playwright@claude-plugins-official`<br>或：<br>`claude mcp remove playwright` | 從 `~/.copilot/mcp-config.json` 刪除 `playwright` 項目。 | `codex mcp remove playwright` |

完整 client 設定與參數見 [`upstream/playwright-mcp/README.md`](upstream/playwright-mcp/README.md)。上游 README 也指出：coding agent 可改用 token 消耗較低的 [Playwright CLI + SKILLS](https://github.com/microsoft/playwright-cli)。

[Back to top](#quick-navigation)

---

## AI 工具文件

| 工具 | 參考文件 | 說明 |
|------|---------|------|
| **Common Prompt** | [`cli-agents/common-prompt.md`](cli-agents/common-prompt.md) / [`cli-agents/common-prompt_zhTW.md`](cli-agents/common-prompt_zhTW.md) | 可追加到 Claude Code、Codex 等 AI 工具設定檔的共用基本守則，包含語言偏好、工作態度與禁止行為 |
| **Cross-Tool Hooks** | [`cli-agents/hooks-cross-tool.md`](cli-agents/hooks-cross-tool.md) | 比較 Claude Code、GitHub Copilot CLI、Codex CLI 的 hook 核心差異，並整理共用 plugin skill + hook 的封裝策略 |
| **Claude Code** | [`cli-agents/claude-code/cc-cli.md`](cli-agents/claude-code/cc-cli.md) | CLI 參數、slash commands、快捷鍵，以及 built-in / custom agent 用法 |
| **GitHub Copilot** | [`cli-agents/github-copilot/gc-cli.md`](cli-agents/github-copilot/gc-cli.md) | CLI 參數、slash commands、custom instructions，以及 built-in / custom agent 用法 |
| **Codex CLI** | [`cli-agents/codex/cx-cli.md`](cli-agents/codex/cx-cli.md) | 安裝、登入、approval / sandbox、`codex exec`、subagents、`AGENTS.md`、slash commands、config，以及 TUI 快捷操作 |

其他工具操作文件索引：[`tool/TOOL.md`](tool/TOOL.md)

[Back to top](#quick-navigation)

---

## Agent 與 Skill 差異

這一節整理目前 repo 內對 **Claude Code** 與 **GitHub Copilot CLI** 的 agent / skill 研究結論。各工具的 CLI 與 agent 使用方式以 [`cli-agents/`](cli-agents/) 下的文件為準。

### 核心區分

**一句話：`agent` 是「誰來做」；`skill` 是「怎麼做」。**

| 面向 | Agent | Skill |
|------|-------|-------|
| 本質 | 專家角色 / 執行者 | SOP / 任務知識包 |
| 系統實際做的事 | 啟動一個專門 agent 或 subagent 去做 | 把對應的 [`SKILL.md`](.claude/skills/skills-governance/SKILL.md) 與附帶資源注入目前 agent 的 context |
| Context | 常有獨立 context，適合隔離探索、測試、review | 多半沿用目前對話 context，屬 just-in-time 指南 |
| 主要關注 | 角色、工具權限、模型、隔離、背景執行、可否委派 | 步驟、模板、範例、腳本、輸出格式 |
| 適合場景 | `security-auditor`、`code-reviewer`、`test-runner` | `skills-governance`、release note / deploy SOP |

### 兩者如何搭配

| 層次 | 用途 |
|------|------|
| custom instructions | 所有任務都應遵守的 repo 慣例與溝通方式 |
| skill | 某一類任務才需要的知識、步驟與模板 |
| agent | 負責執行任務的角色與 runtime 邊界 |
| tool / MCP | 實際能力來源，例如讀檔、改檔、查 GitHub、操作外部服務 |

實務上比較穩的設計通常是：**把知識與流程放 skill，把角色、權限與執行邊界放 agent**。  
例如 [`.claude/skills/`](.claude/skills/skills-governance/SKILL.md) 目前收的就是 repo 專用 skills，不是 agents。

### Claude Code 與 GitHub Copilot 的差異

| 項目 | Claude Code | GitHub Copilot CLI |
|------|-------------|--------------------|
| Agent 定位 | 比較像可編排的 subagent runtime | 比較像 specialist persona + tool profile |
| Skill 定位 | skills 除知識外，還能設定 `allowed-tools`、`context: fork`、`hooks` 等行為 | skills 是 task-specific instructions，可附 scripts / resources，偏 just-in-time workflow |
| Agent 與 Skill 搭配 | custom agent 可透過 `skills` 欄位預載 skills 內容 | custom agent 與 skills 都能共存，但 custom agent 主要負責角色與工具邊界 |
| Agent 裡能否再叫 Agent | 被派出去的 subagent 不能再 spawn subagent；若整個 session 以 `claude --agent` 啟動，主執行緒仍可再派 | custom agent `tools` 支援 `agent` alias，可再叫其他 custom agent，但不建議做太深巢狀 |

### Marketplace / Plugin 能不能放 Agent

可以，但精準說法是：**marketplace 是分發 plugin 的地方；真正承載 agent 的是 plugin。**

| 平台 | marketplace / plugin 能否包含 agent | 典型位置 | 補充 |
|------|-----------------------------------|----------|------|
| Claude Code | 可以 | plugin root 的 `agents/` | plugin 可包含 `skills`、`agents`、`hooks`、`MCP`、`LSP` |
| GitHub Copilot CLI | 可以 | plugin root 的 `agents/`，檔名 `*.agent.md` | plugin 可包含 `agents`、`skills`、`hooks`、`MCP` 等元件 |

不過 **agent 不像 skill 那樣容易跨 cc / gc 共用同一份定義**。兩邊都能透過 plugin / marketplace 發佈 agent，但 frontmatter、檔名格式、可用欄位與 tool naming 都不同：

1. **Claude Code plugin agents** 支援 `skills`、`memory`、`background`、`isolation` 等欄位，但 plugin-shipped agents 不支援 `hooks`、`mcpServers`、`permissionMode`。
2. **GitHub Copilot CLI plugin agents** 使用 `.agent.md` 格式，欄位與 tool aliases 也和 Claude Code 不同。
3. 如果要讓同一個 marketplace root 同時服務 cc 與 gc，**可以共用同一個 plugin root 概念，但 agent 通常仍要各自包 wrapper**；skill 才比較適合共用同一套內容。

### 這個 repo 目前怎麼看

1. [`.claude/skills/`](.claude/skills/sync-all/SKILL.md) 是本 repo 的 **project skill 生態**，只放本 repo 執行維護任務時需要的 workflow。
2. [`cli-agents/`](cli-agents/) 則整理各工具的 CLI、agent 建立、使用與能力邊界。
3. 如果未來要新增可分發的 plugin / marketplace，cc 與 gc 都做得到，但不應假設一份 agent 定義可直接跨兩邊共用。
4. 如果你在設計新能力時猶豫該做 agent 還是 skill，先問自己一句：**我要的是專家，還是手冊？** 要專家就做 agent；要手冊就做 skill。

[Back to top](#quick-navigation)

---

## 腳本文件

Repo 維護與自動化腳本的總索引在 [`scripts/SCRIPTS.md`](scripts/SCRIPTS.md)。

目前已收錄：

- [`scripts/link-agent-skills.ps1`](scripts/link-agent-skills.ps1)：在 Windows 以 junction 將 `.agents/skills` 連到 `.claude/skills`
- [`scripts/link-agent-skills.sh`](scripts/link-agent-skills.sh)：在 Bash 環境以 symlink 將 `.agents/skills` 連到 `.claude/skills`
- [`scripts/remove-local-git-user.ps1`](scripts/remove-local-git-user.ps1)：遞迴掃描指定路徑下的 Git repository / worktree，移除 local Git config 的 `[user]` section

之後若 `scripts/` 目錄新增腳本，也應同步補充到 [`scripts/SCRIPTS.md`](scripts/SCRIPTS.md)。

[Back to top](#quick-navigation)

---

## 一鍵安裝腳本

除了 `scripts/` 下的 repo 維護腳本，本 repo 另外還有九支會寫入**使用者家目錄**（repo 之外）的一鍵安裝腳本，各自服務不同目的，因此不收錄在 [`scripts/SCRIPTS.md`](scripts/SCRIPTS.md)。（另有兩支性質相同的桌面應用程式熱鍵腳本 [`scripts/setup-cc-desktop-ahk.ps1`](scripts/setup-cc-desktop-ahk.ps1) 與 [`scripts/setup-cx-desktop-ahk.ps1`](scripts/setup-cx-desktop-ahk.ps1)，因為放在 `scripts/` 下，改收錄在 [`scripts/SCRIPTS.md`](scripts/SCRIPTS.md) 裡，不重複列在這張表。）

> 不想個別記住並手動執行下面這些腳本嗎？[`scripts/install-all.ps1` / `.sh`](scripts/SCRIPTS.md#install-all) 提供一個互動選單，可以一次選擇要安裝 Claude Code CLI（`install-cc`）、Codex CLI（`install-cx`）、`tool/PowerShell/install.ps1`、共用系統提示詞（`install-sys-prompt`）與/或桌面應用程式熱鍵（[`setup-cc-desktop-ahk.ps1`](scripts/SCRIPTS.md#setup-cc-desktop-ahkps1) / [`setup-cx-desktop-ahk.ps1`](scripts/SCRIPTS.md#setup-cx-desktop-ahkps1)，僅 Windows）。

| 腳本 | 安裝目標 | 內容 | 範例 |
|------|----------|------|------|
| [`cli-agents/claude-code/install-cc.ps1`](cli-agents/claude-code/install-cc.ps1) | 系統層級（Node.js/npm）+ `$env:USERPROFILE\.claude\` | 三步驟：1) 缺 npm 時用 winget 安裝 Node.js LTS；已有 npm 且是 winget 裝的（`winget list -e --id OpenJS.NodeJS.LTS` 找得到）才執行 `winget upgrade`，若 npm 是用其他方式裝的（如 nvm）則略過更新、直接沿用；2) `npm install -g @anthropic-ai/claude-code` 安裝/更新 Claude Code CLI；3) 呼叫同資料夾的 [`install-statusline.ps1`](cli-agents/claude-code/install-statusline.ps1) 部署 statusLine 與 hooks（此步驟用內建 `ConvertFrom-Json`/`ConvertTo-Json`，不需要 `jq`） | `powershell -ExecutionPolicy Bypass -File .\cli-agents\claude-code\install-cc.ps1` |
| [`cli-agents/claude-code/install-cc.sh`](cli-agents/claude-code/install-cc.sh) | 系統層級（Node.js/npm/jq）+ `~/.claude/` | macOS 版對應腳本，同樣三步驟，改用 Homebrew：缺 npm 時 `brew install node`；已有 npm 且是 Homebrew 裝的（`brew list node` 找得到）才 `brew upgrade node`，否則略過更新；第三步前先確保 `jq` 存在（缺的話用 `brew install jq` 補上），再呼叫 [`install-statusline.sh`](cli-agents/claude-code/install-statusline.sh) | `bash ./cli-agents/claude-code/install-cc.sh` |
| [`cli-agents/claude-code/install-statusline.ps1`](cli-agents/claude-code/install-statusline.ps1) | `~/.claude/` | 複製 [`statusline-command.sh`](cli-agents/claude-code/statusline-command.sh) 與 [`hooks/*.sh`](cli-agents/claude-code/hooks/)；在 `~/.claude/settings.json` 注入 `statusLine`，以及 `UserPromptSubmit` / `PreToolUse` / `Stop` 三個即時狀態追蹤 hooks | `powershell -ExecutionPolicy Bypass -File .\cli-agents\claude-code\install-statusline.ps1` |
| [`cli-agents/claude-code/install-statusline.sh`](cli-agents/claude-code/install-statusline.sh) | `~/.claude/` | `install-statusline.ps1` 的 macOS/Linux 版本，邏輯相同；用 `jq` 安全改寫 `settings.json`（需先自行安裝，例如 `brew install jq`），未安裝時會直接報錯並提示 | `bash ./cli-agents/claude-code/install-statusline.sh` |
| [`cli-agents/codex/install-cx.ps1`](cli-agents/codex/install-cx.ps1) | 系統層級（Node.js/npm）+ `$env:USERPROFILE\.codex\pets\` | 三步驟：1) 與 `install-cc.ps1` 相同的 npm 檢查/安裝/更新邏輯（winget，只在 `winget list` 找得到時才 upgrade）；2) `npm install -g @openai/codex` 安裝/更新 Codex CLI；3) 把同資料夾的 [`pets/`](cli-agents/codex/pets/) 遞迴複製到 `~/.codex/pets/`（覆蓋同名檔案，不刪除目的地多出來的檔案） | `powershell -ExecutionPolicy Bypass -File .\cli-agents\codex\install-cx.ps1` |
| [`cli-agents/codex/install-cx.sh`](cli-agents/codex/install-cx.sh) | 系統層級（Node.js/npm）+ `~/.codex/pets/` | macOS 版對應腳本，同樣三步驟，改用 Homebrew 處理 npm（邏輯與 `install-cc.sh` 相同），第三步用 `cp -Rf` 把 [`pets/`](cli-agents/codex/pets/) 複製到 `~/.codex/pets/` | `bash ./cli-agents/codex/install-cx.sh` |
| [`cli-agents/install-sys-prompt.ps1`](cli-agents/install-sys-prompt.ps1) | `$env:USERPROFILE\.claude\`、`$env:USERPROFILE\.codex\`、`$env:USERPROFILE\.copilot\` | 若目標檔已存在，先改名備份為 `<檔名>_yyMMddHHmmss`，再複製三個工具的提示範本；然後將 [`common-prompt.md`](cli-agents/common-prompt.md) append 到 `CLAUDE.md`、`AGENTS.md` 與 `copilot-instructions.md` 底部 | `powershell -ExecutionPolicy Bypass -File .\cli-agents\install-sys-prompt.ps1` |
| [`cli-agents/install-sys-prompt.sh`](cli-agents/install-sys-prompt.sh) | `$HOME/.claude/`、`$HOME/.codex/`、`$HOME/.copilot/` | 與 PowerShell 版本相同，適用於 POSIX shell、macOS、Linux 與 Git Bash；先部署範本，再將 [`common-prompt.md`](cli-agents/common-prompt.md) append 到 `CLAUDE.md`、`AGENTS.md` 與 `copilot-instructions.md` 底部 | `bash ./cli-agents/install-sys-prompt.sh` |
| [`tool/PowerShell/install.ps1`](tool/PowerShell/install.ps1) | Documents 下的 `PowerShell\`（profile）+ `$HOME\.config\powershell\`（其餘腳本） | 複製 [`Microsoft.PowerShell_profile.ps1`](tool/PowerShell/Microsoft.PowerShell_profile.ps1) 到 pwsh profile 資料夾；其餘 `tool/PowerShell/` 下的腳本（`local_profile.ps1`、`Exe-*.ps1`、`Set-*.ps1` 等）複製到 `.config\powershell\` | `powershell -ExecutionPolicy Bypass -File .\tool\PowerShell\install.ps1` |

`install-cc.ps1` / `install-cc.sh` / `install-cx.ps1` / `install-cx.sh` 會呼叫系統套件管理器（winget / Homebrew）安裝或更新 Node.js，以及用 `npm install -g` 安裝/更新 Claude Code CLI 或 Codex CLI，這些是系統層級變更，不像其餘腳本只複製 repo 內的檔案。

`install-sys-prompt.ps1` 與 `install-sys-prompt.sh` 都可重複執行；每次會先將既有目標檔案改名備份（`<檔名>_yyMMddHHmmss`，同一次執行的三個檔案共用同一個時間戳記），再複製範本並將 [`common-prompt.md`](cli-agents/common-prompt.md) 追加到 `CLAUDE.md`、`AGENTS.md` 與 `copilot-instructions.md` 底部。備份不會自動清除，長期重複執行會在同目錄下累積多個備份檔，需要時可自行手動清理。若來源檔案不存在或複製失敗，腳本會停止並回傳錯誤，且在檢查完成前不建立、不改名、不覆寫任何目標檔。完整行為與風險說明見各自的來源目錄文件：[`cc-cli.md`](cli-agents/claude-code/cc-cli.md)、[`tool/TOOL.md`](tool/TOOL.md)。

### 共用 Prompt 安裝器：SBE 腳本行為

以下案例同時適用於 [`install-sys-prompt.ps1`](cli-agents/install-sys-prompt.ps1) 與 [`install-sys-prompt.sh`](cli-agents/install-sys-prompt.sh)：

| 前置狀態 | 執行 | 預期結果 |
|----------|------|----------|
| 三個目標目錄不存在，來源範本與 [`common-prompt.md`](cli-agents/common-prompt.md) 都存在 | 執行安裝器 | 建立 `.claude`、`.codex`、`.copilot`；`CLAUDE.md`、`AGENTS.md`、`copilot-instructions.md` 都由各自範本加上 [`common-prompt.md`](cli-agents/common-prompt.md) 組成；不產生任何備份檔 |
| `CLAUDE.md` 已存在且內容為自訂文字 | 再次執行安裝器 | 先把現有 `CLAUDE.md` 改名為 `CLAUDE.md_yyMMddHHmmss`（原自訂文字完整保留在備份檔中），再以 Claude 範本重新產生 `CLAUDE.md` 並將 [`common-prompt.md`](cli-agents/common-prompt.md) append 到底部 |
| 任一來源範本或 [`common-prompt.md`](cli-agents/common-prompt.md) 不存在 | 執行安裝器 | 顯示來源檔案錯誤、回傳非零狀態，且在檢查完成前不建立、不改名、不覆寫任何目標檔 |

PowerShell 範例：

```powershell
powershell -ExecutionPolicy Bypass -File .\cli-agents\install-sys-prompt.ps1
```

首次執行（目標檔皆不存在）預期成功輸出會列出三個 `Template` 與三個 `Common prompt` `[OK]` 項目，最後顯示 `Done.`；重複執行時，每個目標檔前面會多一行 `[Backup] <原檔> -> <原檔>_yyMMddHHmmss`。shell 版本的成功輸出語意相同。

[Back to top](#quick-navigation)

---

## Project Skills

目前 repo 內自製 project skills 維護在 [`.claude/skills/`](.claude/skills/skills-governance/SKILL.md)：

| 位置 | 定位 |
|------|------|
| [`.claude/skills/`](.claude/skills/skills-governance/SKILL.md) | 專案內部 project skills；只放治理規則、維護政策與 repo 專用 workflow，例如 [`skills-governance`](.claude/skills/skills-governance/SKILL.md)。 |

這些 skills 的用途是讓本 repo 的維護規則可以被 AI 工具即時載入，而不是對外發佈成可安裝 plugin。

[Back to top](#quick-navigation)

---

## 目錄結構

```
ai-research/
├── upstream/                 # 上游 submodule 容器（skill、plugin、MCP server 等）
│   ├── anthropic-skills/     # Anthropic 上游 skills submodule
│   ├── webwright/            # Microsoft Webwright 瀏覽器代理 submodule
│   ├── codex-plugin-cc/      # OpenAI Codex plugin for Claude Code submodule
│   └── playwright-mcp/       # Microsoft Playwright MCP server submodule
├── cli-agents/               # 各 CLI agent 的參考文件與使用者級別設定範本
│   ├── claude-code/          # Claude Code CLI 參考
│   │   └── .claude/          # 使用者級別設定範本（複製到 ~/.claude/ 生效）
│   ├── github-copilot/       # GitHub Copilot CLI + custom instructions
│   │   └── .copilot/         # 使用者級別設定範本（複製到 ~/.copilot/ 生效）
│   └── codex/                # Codex CLI 參考
│       └── cx-cli.md
├── scripts/                  # 維護與自動化腳本文件
│   └── SCRIPTS.md            # scripts/ 的唯一索引
├── .claude/skills/           # repo 專用 project skills
│   ├── _shared/              # 共用協議（upstream-sync-protocol）
│   ├── skills-governance/    # project skill 治理規則
│   ├── anthropic-skills-sync/ # Anthropic sync 維運 skill
│   ├── cli-doc-sync/         # CLI 文件同步工具
│   └── sync-all/             # 統一 orchestrator：Dependabot PR → invoke 各 sync skill
├── .github/
│   └── dependabot.yml        # 每日自動偵測所有 submodule 上游變更
├── AGENTS.md                 # English skill lookup and repo guidance
├── AGENTS_zhTW.md            # 繁中對照版 skill lookup and repo guidance
├── CLAUDE.md                 # Claude Code project instructions
├── tool/                     # 工具操作文件
│   ├── TOOL.md
│   └── PowerShell/           # PowerShell profile 與工具腳本
```

[Back to top](#quick-navigation)

