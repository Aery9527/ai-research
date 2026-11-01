# Scripts

> 這裡集中管理 `ai-research` 內的維護腳本文件。之後若新增 `.ps1`、`.cmd`、`.py` 或其他自動化工具，請一律先在這份文件補上索引與使用說明。

```mermaid
flowchart LR
    A["新增或修改腳本"] --> B["更新 scripts/SCRIPTS.md 索引"]
    B --> C["確認用途、參數、風險、範例"]
    C --> D["再執行或分享腳本"]
```

---

## Quick Navigation

- [用途與維護原則](#用途與維護原則)
- [腳本索引](#腳本索引)
- [腳本詳述](#腳本詳述)
  - [Link Agent Skills](#link-agent-skills)
  - [Install All](#install-all)
  - [`remove-local-git-user.ps1`](#remove-local-git-userps1)
  - [`setup-cc-desktop-ahk.ps1`](#setup-cc-desktop-ahkps1)
  - [`setup-cx-desktop-ahk.ps1`](#setup-cx-desktop-ahkps1)
- [新增腳本時建議補充的欄位](#新增腳本時建議補充的欄位)

[Back to top](#quick-navigation)

---

## 用途與維護原則

`scripts/` 用來放：

- repo 維護輔助工具
- 重複性清理或修正腳本
- 需要在本機或多個 repo/worktree 上批次執行的自動化操作

`scripts/` 底下大多數腳本只操作 repo 內部或本機既有設定（例如 Git config），但也有例外：像 [`setup-cc-desktop-ahk.ps1`](#setup-cc-desktop-ahkps1) 這種一鍵安裝／設定型腳本，即使會寫入使用者家目錄（repo 之外），只要放在 `scripts/` 下就一律在這份文件收錄索引，不因為寫入範圍而排除。

為了避免腳本散落但沒有文件，這份 `SCRIPTS.md` 應該同時扮演兩個角色：

1. **索引入口**：快速知道目前有哪些腳本。
2. **操作文件**：知道每支腳本會改什麼、怎麼跑、有哪些風險。

[Back to top](#quick-navigation)

---

## 腳本索引

| 腳本 | 類型 | 用途 | 是否修改檔案 | 備註 |
|------|------|------|--------------|------|
| [`link-agent-skills.ps1`](./link-agent-skills.ps1) | PowerShell | 建立、修復或移除本機 `.claude/skills` 到 [.agents/skills](../.agents/skills/) 的 Windows junction | 會，只管理本機連結 | 保留來源內容；遇到實體目錄中止；支援 PowerShell 5.1 以上 |
| [`link-agent-skills.sh`](./link-agent-skills.sh) | Bash | 建立、修復或移除本機 `.claude/skills` 到 [.agents/skills](../.agents/skills/) 的 Unix symlink | 會，只管理本機連結 | 保留來源內容；遇到實體目錄中止；需要原生 symlink 支援 |
| [`install-all.ps1`](./install-all.ps1) | PowerShell | 互動式選單，依選擇呼叫 [`install-cc.ps1`](../cli-agents/claude-code/install-cc.ps1)、[`install-cx.ps1`](../cli-agents/codex/install-cx.ps1)、[`tool/PowerShell/install.ps1`](../tool/PowerShell/install.ps1)、[`install-sys-prompt.ps1`](../cli-agents/install-sys-prompt.ps1)、[`setup-cc-desktop-ahk.ps1`](#setup-cc-desktop-ahkps1)、[`setup-cx-desktop-ahk.ps1`](#setup-cx-desktop-ahkps1) | 不直接修改檔案，但會觸發被呼叫腳本對使用者家目錄的修改 | 任一項失敗即中斷，不繼續安裝其餘項目；檔案含中文字，需要 UTF-8 BOM 才能被 PowerShell 5.1 正確解析 |
| [`install-all.sh`](./install-all.sh) | Bash | `install-all.ps1` 的 macOS/Linux 對應版本，呼叫 [`install-cc.sh`](../cli-agents/claude-code/install-cc.sh)、[`install-cx.sh`](../cli-agents/codex/install-cx.sh)、[`install-sys-prompt.sh`](../cli-agents/install-sys-prompt.sh) | 不直接修改檔案，但會觸發被呼叫腳本對使用者家目錄的修改 | 選項 3（PowerShell 腳本）、5（Claude Desktop 熱鍵）、6（ChatGPT Desktop 熱鍵）在這個版本僅顯示略過訊息，不執行任何動作；任一項失敗即中斷 |
| [`remove-local-git-user.ps1`](./remove-local-git-user.ps1) | PowerShell | 遞迴掃描指定路徑下的 Git repository / worktree，移除 local git config 中的 `[user]` section | 會，直接覆寫 Git config | 不建立 backup；遇到異常 config 會跳過 |
| [`setup-cc-desktop-ahk.ps1`](./setup-cc-desktop-ahk.ps1) | PowerShell | 查詢 Claude Desktop 的 AppID，缺 AutoHotkey v2 時用 winget 安裝，寫入切換 Claude Desktop 顯示/隱藏的 hotkey 腳本並設定開機自動執行 | 會，寫入 `$env:LOCALAPPDATA\ClaudeHotkey\` 與 Startup 資料夾（repo 之外） | 找不到唯一的 Claude Desktop AppID 時會直接中止；缺 winget 時需手動安裝 AutoHotkey v2 |
| [`setup-cx-desktop-ahk.ps1`](./setup-cx-desktop-ahk.ps1) | PowerShell | `setup-cc-desktop-ahk.ps1` 的 ChatGPT Desktop 版本，同樣流程改成查詢 ChatGPT 的 AppID，寫入切換 ChatGPT Desktop 顯示/隱藏的 hotkey 腳本並設定開機自動執行 | 會，寫入 `$env:LOCALAPPDATA\ChatGPTHotkey\` 與 Startup 資料夾（repo 之外） | 熱鍵為 `Alt+Space`，會覆蓋 Windows 內建的視窗系統選單快捷鍵；找不到唯一的 ChatGPT Desktop AppID 時會直接中止 |

[Back to top](#quick-navigation)

---

## 腳本詳述

### Link Agent Skills

#### 目的

- [link-agent-skills.ps1](link-agent-skills.ps1) 與 [link-agent-skills.sh](link-agent-skills.sh) 將本機 `.claude/skills` 連到實體 [.agents/skills](../.agents/skills/)，讓 Claude Code 與其他 agent 使用同一批專案 skills。
- PowerShell 版使用 Windows junction；Bash 版使用 Unix symlink。

#### 參數與選單

- 兩支腳本都沒有命令列參數，執行後選擇模式：

| 選項 | 行為 |
|------|------|
| `0` | 取消，不做任何修改 |
| `1` | 建立或修復整個 skills 目錄的連結 |
| `3` | 移除指向此專案 [.agents/skills](../.agents/skills/) 的連結，保留來源內容 |

- 其他選項均回傳非零結束碼；不提供逐一 skill 連結模式。

#### 行為與限制

- [.agents/skills](../.agents/skills/) 必須是存在的實體目錄；腳本不負責搬移 skills。
- 建立時會建立缺少的 `.claude` 父目錄；若已有連結，僅移除連結本身，再指向目前專案的 skills。
- 若 `.claude/skills` 是實體目錄或檔案，腳本會中止並保留內容，必須先完成內容遷移。
- 取消連結時，若連結指向其他位置，腳本會中止並保留該連結；連結不存在時不做修改。
- 兩支腳本只管理本機連結，不修改 [.gitignore](../.gitignore)；該檔固定忽略 `.claude/skills`。
- PowerShell 版支援 Windows PowerShell 5.1 以上；Bash 版需要原生 symlink 支援，使用 `nativestrict` 防止 Git Bash 複製成實體目錄，缺少 symlink 權限時會直接失敗。
- 修復會先移除既有連結；若建立新連結失敗，來源內容保留，Windows 使用者可用 PowerShell 版重建連結。
- 連結建立或修復後，使用專案 skills 前必須依目前 agent 環境支援的方式重新載入 skills。

#### 範例

- Windows PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link-agent-skills.ps1
```

- macOS / Linux：

```bash
bash ./scripts/link-agent-skills.sh
```

- 選擇 `1` 後的成功輸出包含：

```text
[OK] .claude/skills -> .agents/skills
```

---

### Install All

#### 目的

[`install-all.ps1`](./install-all.ps1) 與 [`install-all.sh`](./install-all.sh) 是一鍵安裝的選單入口，讓使用者不用分別記住並手動執行 [`install-cc.ps1`/`.sh`](../cli-agents/claude-code/)、[`install-cx.ps1`/`.sh`](../cli-agents/codex/)、[`tool/PowerShell/install.ps1`](../tool/PowerShell/install.ps1)、[`install-sys-prompt.ps1`/`.sh`](../cli-agents/)、[`setup-cc-desktop-ahk.ps1`](#setup-cc-desktop-ahkps1)、[`setup-cx-desktop-ahk.ps1`](#setup-cx-desktop-ahkps1) 這幾支各自獨立的安裝腳本。

兩個版本功能相同，差異在於平台限制：

- PowerShell 版六個選項都能執行。
- Bash 版選項 1、2、4 真的會執行；選項 3（PowerShell 腳本）、5（Claude Desktop 熱鍵）、6（ChatGPT Desktop 熱鍵）在 macOS/Linux 上都不適用，選到時只會印出略過訊息，不做任何動作。

#### 參數

兩支腳本都沒有命令列參數，執行後以互動輸入決定要安裝哪些項目。

| 輸入 | 行為 |
|------|------|
| 留空 或 `0` | 全部安裝（依固定順序 1 → 2 → 3 → 4 → 5 → 6） |
| `1` | 只安裝 Claude Code CLI（呼叫 [`install-cc.ps1`/`.sh`](../cli-agents/claude-code/)） |
| `2` | 只安裝 Codex CLI（呼叫 [`install-cx.ps1`/`.sh`](../cli-agents/codex/)） |
| `3` | 只安裝 PowerShell 腳本（呼叫 [`tool/PowerShell/install.ps1`](../tool/PowerShell/install.ps1)；Bash 版僅顯示略過訊息） |
| `4` | 只安裝共用系統提示詞（呼叫 [`install-sys-prompt.ps1`/`.sh`](../cli-agents/)） |
| `5` | 只設定 Claude Desktop 熱鍵（呼叫 [`setup-cc-desktop-ahk.ps1`](#setup-cc-desktop-ahkps1)；Bash 版僅顯示略過訊息） |
| `6` | 只設定 ChatGPT Desktop 熱鍵（呼叫 [`setup-cx-desktop-ahk.ps1`](#setup-cx-desktop-ahkps1)；Bash 版僅顯示略過訊息） |
| 逗號分隔多選，例如 `1,4` | 安裝多項，執行順序固定為 1 → 2 → 3 → 4 → 5 → 6，與輸入順序無關 |
| 無效編號（例如 `7`、`abc`） | 顯示錯誤並以非零狀態結束，不執行任何項目 |

#### 它實際在做什麼

1. 顯示選單與說明文字。
2. 讀取使用者輸入，解析成一組要安裝的項目（預設全選）。
3. 依固定順序 1 → 2 → 3 → 4 → 5 → 6 呼叫對應的子腳本。
4. 每個子腳本執行後都會檢查其結束代碼；只要有一項失敗，立即停止，不繼續安裝其餘項目。

#### 風險與限制

- **任一項失敗就中斷**，不會嘗試繼續安裝清單中的其餘項目；這是刻意設計（子腳本彼此仍是各自獨立、有系統層級副作用的安裝流程，中斷後可以修好問題再單獨重跑失敗的那一項）。
- 子腳本本身的風險（呼叫 winget/Homebrew 安裝或更新 Node.js、`npm install -g` 安裝 CLI 等）請參考 [`cc-cli.md`](../cli-agents/claude-code/cc-cli.md)、[`cx-cli.md`](../cli-agents/codex/cx-cli.md) 與 [`CLI-AGENTS.md`](../cli-agents/CLI-AGENTS.md#一鍵安裝腳本) 的「一鍵安裝腳本」章節；選項 5、6（`setup-cc-desktop-ahk.ps1` / `setup-cx-desktop-ahk.ps1`）的風險見各自的章節（[`setup-cc-desktop-ahk.ps1`](#setup-cc-desktop-ahkps1)、[`setup-cx-desktop-ahk.ps1`](#setup-cx-desktop-ahkps1)）。
- `install-all.ps1` 含有中文選單文字，檔案必須保留 UTF-8 BOM 才能被 Windows PowerShell 5.1 正確解析；`install-all.sh` 則相反，開頭不可以有 BOM（會破壞 `#!/usr/bin/env bash` shebang 辨識）。

#### 範例

Windows PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-all.ps1
```

Bash：

```bash
bash ./scripts/install-all.sh
```

#### 預期輸出

```text
==========================================
   Install All
==========================================

  [1] Claude Code CLI (install-cc)
  [2] Codex CLI (install-cx)
  [3] PowerShell 腳本 (install.ps1)
  [4] 系統提示詞 (install-sys-prompt)
  [5] Claude Desktop 熱鍵 (setup-cc-desktop-ahk)
  [6] ChatGPT Desktop 熱鍵 (setup-cx-desktop-ahk)

  [0] 全部安裝（預設）

==========================================
請輸入要安裝的項目編號，可用逗號分隔多選（例如 1,4；留空或輸入 0 = 全部安裝）:

=== [1] Claude Code CLI (install-cc) ===
...

=== [2] Codex CLI (install-cx) ===
...

=== [3] PowerShell 腳本 (install.ps1) ===
...

=== [4] 系統提示詞 (install-sys-prompt) ===
...

=== [5] Claude Desktop 熱鍵 (setup-cc-desktop-ahk) ===
...

=== [6] ChatGPT Desktop 熱鍵 (setup-cx-desktop-ahk) ===
...

[OK] 全部完成
```

若中途有項目失敗，會改為顯示 `[X] ERROR: ... 失敗 (exit N)` 並直接以非零狀態結束，不會出現 `[OK] 全部完成`。

---

### `remove-local-git-user.ps1`

#### 目的

批次移除指定根目錄下所有 Git repository（包含一般 repo 與使用 `gitdir:` pointer 的 worktree）之 **local** Git config 裡的 `[user]` section。

這適合用在以下情境：

- 某些 repo 曾被設定過 local `user.name` / `user.email`
- 想回到 global Git identity，避免 local config 覆蓋全域設定
- 需要一次清理多個 repo 或 worktree 的本機 Git 使用者資訊

#### 參數

| 參數 | 型別 | 預設值 | 說明 |
|------|------|--------|------|
| `$RootPath` | `string` | `.` | 掃描起點。腳本會從這個目錄往下遞迴搜尋 `.git` |

#### 它實際在做什麼

1. 將 `$RootPath` 解析成絕對路徑。
2. 以 BFS 方式遞迴掃描子目錄。
3. 對每個找到的 `.git`：
   - 如果 `.git` 是資料夾，視為一般 repo，讀取 `.git/config`
   - 如果 `.git` 是檔案，視為 worktree / gitdir pointer，解析 `gitdir: ...` 後找到真正的 `config`
4. 將重複的 config 路徑去重，避免同一份 config 被重複處理。
5. 逐一讀取 config 原始 bytes，找出 section header。
6. 若存在且只存在一個精確的 `[user]` section，則把該 section 從 header 起點一路刪到下一個 section header 之前。
7. 將更新後的 bytes 直接寫回原 config 檔。
8. 最後輸出摘要：`Updated`、`Unchanged`、`Skipped`。

#### Section 判定規則

這支腳本只會移除 **精確名稱為 `[user]`** 的 section，且比對不分大小寫。

- 會移除：`[user]`
- 不會當成可刪除目標：`[user "foo"]`、`[user.name]`、其他非標準或不同名稱 section

#### 安全性與保守行為

這支腳本偏保守，遇到不確定情況會跳過而不是硬改：

- 找不到任何 Git config：輸出提示並結束
- 找不到 `[user]` section：列為 `Unchanged`
- 同一份 config 出現多個 `[user]` section：列為 `Skipped`
- `.git` pointer 格式不合法：警告並跳過
- 找到 `.git` 但對應 `config` 不存在：警告並跳過
- 某些目錄無法存取：警告並繼續掃描其他目錄

#### 風險與限制

- **會直接覆寫原始 Git config，沒有自動 backup。**
- 腳本是以 bytes 方式移除區段，重點是保留原始檔大部分內容與換行形式，而不是重排整份 INI。
- 若 `[user]` section 前後已有空白行，刪除後可能留下原本結構中的空白，不會額外做格式化清理。
- 若 `RootPath` 本身不存在，因為腳本使用 `Resolve-Path` 並設定 `$ErrorActionPreference = 'Stop'`，會直接拋錯終止。

#### 範例

從目前目錄開始掃描：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\remove-local-git-user.ps1
```

指定某個根目錄掃描：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\remove-local-git-user.ps1 -RootPath "C:\Users\aerylin\IdeaProjects"
```

若想先自行備份再執行，可以先手動備份目標 repo 的 `.git\config` 或 worktree 對應的 `config`。

#### 預期輸出

成功執行時，會看到每份 config 的處理結果。`Write-Warning` 的前綴會跟 PowerShell 語系有關，因此可能是 `WARNING:`、`警告:` 或其他本地化字樣，例如：

```text
Updated: C:\path\to\repo\.git\config
No [user] section: C:\path\to\another\.git\config
警告: Skipped malformed config: multiple [user] sections: C:\path\to\broken\.git\config

Summary
  Updated : 1
  Unchanged: 1
  Skipped : 1
```

---

### `setup-cc-desktop-ahk.ps1`

#### 目的

一鍵設定 Claude Desktop 的 AutoHotkey 快捷鍵：偵測本機 Claude Desktop 的 AppID 與 AutoHotkey v2，寫入可切換 Claude Desktop 顯示/隱藏的 `.ahk` 腳本，並設定開機自動啟動。

#### 參數

沒有命令列參數，執行後直接依序完成三個步驟。

#### 它實際在做什麼

1. **Step 1 — Claude Desktop**：呼叫 `Get-StartApps` 篩選 `Name -eq 'Claude'`，要求剛好找到一筆有效 AppID，否則直接中止（找不到或找到多筆都視為錯誤，不會用猜的）。
2. **Step 2 — AutoHotkey v2**：依序檢查 `AutoHotkey64.exe` / `AutoHotkey.exe` 是否在 `PATH` 或 `Program Files\AutoHotkey\v2\` 下；找不到時用 `winget install --exact --id AutoHotkey.AutoHotkey` 安裝。
3. **Step 3 — Hotkey 與開機啟動**：把 AppID 寫入 `$env:LOCALAPPDATA\ClaudeHotkey\claude-hotkey.ahk`（`Alt+Shift+Space` 切換 Claude Desktop：未啟動則啟動、已啟動未 focus 則叫到前景、已 focus 則關閉），並在 Startup 資料夾建立 `Claude Desktop Hotkey.lnk` 捷徑指向 AutoHotkey 執行檔（帶上腳本路徑當參數）。

腳本可重複執行：`.ahk` 內容與 Startup 捷徑每次都會被覆寫成最新狀態，AutoHotkey 已安裝時會略過 Step 2 的安裝動作。

#### 風險與限制

- **會寫入 repo 之外的使用者目錄**：`$env:LOCALAPPDATA\ClaudeHotkey\` 與 Startup 資料夾，兩者都會被直接覆寫，沒有 backup。
- 找不到唯一的 Claude Desktop AppID（未安裝、或有多筆同名項目）時會直接拋錯中止，不會嘗試其他猜測方式。
- 缺 AutoHotkey v2 且系統沒有 `winget` 時會直接報錯，需要手動安裝後再重跑。
- 僅支援從 Microsoft Store 安裝的 Claude Desktop（AppID 啟動方式）；官網下載版需另外把寫入的 `.ahk` 內容中 `Run "shell:AppsFolder\..."` 改成實際的 `Claude.exe` 路徑。

#### 範例

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-cc-desktop-ahk.ps1
```

#### 預期輸出

```text
=== Claude Desktop Hotkey Setup ===
--- Step 1: Claude Desktop ---
  [OK] Found exactly one Claude Desktop AppID.
--- Step 2: AutoHotkey v2 ---
  [OK] Found AutoHotkey v2: C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
--- Step 3: Hotkey and startup ---
  [OK] Wrote hotkey script: C:\Users\<user>\AppData\Local\ClaudeHotkey\claude-hotkey.ahk
  [OK] Configured startup shortcut: C:\Users\<user>\...\Startup\Claude Desktop Hotkey.lnk

Done. Alt + Shift + Space now toggles Claude Desktop.
```

---

### `setup-cx-desktop-ahk.ps1`

#### 目的

[`setup-cc-desktop-ahk.ps1`](#setup-cc-desktop-ahkps1) 的 ChatGPT Desktop 版本：同一套三步驟流程（查 AppID → 確認 AutoHotkey v2 → 寫入 hotkey 腳本並設定開機啟動），只是改成偵測 ChatGPT Desktop。ChatGPT Desktop 底層套件名稱是 `OpenAI.Codex`（`Get-StartApps` 顯示的 `Name` 仍是精確值 `ChatGPT`），因此沿用跟 Claude 版一致的比對邏輯。

#### 參數

沒有命令列參數，執行後直接依序完成三個步驟。

#### 它實際在做什麼

1. **Step 1 — ChatGPT Desktop**：呼叫 `Get-StartApps` 篩選 `Name -eq 'ChatGPT'`，要求剛好找到一筆有效 AppID，否則直接中止。
2. **Step 2 — AutoHotkey v2**：跟 [`setup-cc-desktop-ahk.ps1`](#setup-cc-desktop-ahkps1) 相同的偵測／安裝邏輯。
3. **Step 3 — Hotkey 與開機啟動**：把 AppID 寫入 `$env:LOCALAPPDATA\ChatGPTHotkey\chatgpt-hotkey.ahk`（`Alt+Space` 切換 ChatGPT Desktop：未啟動則啟動、已啟動未 focus 則叫到前景、已 focus 則關閉），並在 Startup 資料夾建立 `ChatGPT Desktop Hotkey.lnk` 捷徑指向 AutoHotkey 執行檔。

腳本可重複執行，行為與 [`setup-cc-desktop-ahk.ps1`](#setup-cc-desktop-ahkps1) 相同。

#### 風險與限制

- **會寫入 repo 之外的使用者目錄**：`$env:LOCALAPPDATA\ChatGPTHotkey\` 與 Startup 資料夾，兩者都會被直接覆寫，沒有 backup。
- **`Alt+Space` 是 Windows 內建的視窗系統選單快捷鍵**（開啟目前視窗左上角那個選單），此腳本執行期間會把它全域改綁成切換 ChatGPT Desktop，等於覆蓋掉原本的系統行為。
- **`Alt+Space` 也是 PowerToys Run 的預設啟動熱鍵。** 如果本機有裝 PowerToys 且 PowerToys Run 模組是開啟的，會跟這支腳本搶同一組全域熱鍵；先啟動的行程才會生效，需要自行在其中一邊改熱鍵或關閉衝突的模組。
- **UAC 提示視窗（secure desktop）期間這組熱鍵不會生效**：AutoHotkey 是一般權限的行程，Windows 切到 secure desktop 顯示 UAC 對話框時，非系統層級的行程無法對該畫面送出輸入，等 UAC 對話框關閉、切回一般桌面後熱鍵才會恢復作用。同理，如果 ChatGPT Desktop 本身以系統管理員權限啟動（一般情況下不會），非提升權限的 AutoHotkey 腳本也可能無法對它送出視窗操作。
- 若同時執行 [`setup-cc-desktop-ahk.ps1`](#setup-cc-desktop-ahkps1) 與本腳本，兩支 `.ahk` 是各自獨立的 process；由於熱鍵不同（`Alt+Shift+Space` vs `Alt+Space`）不會互相搶注冊，但若之後改成同一組熱鍵，Windows 只有先註冊的行程會生效。
- 找不到唯一的 ChatGPT Desktop AppID（未安裝、或有多筆同名項目）時會直接拋錯中止。
- 缺 AutoHotkey v2 且系統沒有 `winget` 時會直接報錯，需要手動安裝後再重跑。

#### 範例

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-cx-desktop-ahk.ps1
```

#### 預期輸出

```text
=== ChatGPT Desktop Hotkey Setup ===
--- Step 1: ChatGPT Desktop ---
  [OK] Found exactly one ChatGPT Desktop AppID.
--- Step 2: AutoHotkey v2 ---
  [OK] Found AutoHotkey v2: C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
--- Step 3: Hotkey and startup ---
  [OK] Wrote hotkey script: C:\Users\<user>\AppData\Local\ChatGPTHotkey\chatgpt-hotkey.ahk
  [OK] Configured startup shortcut: C:\Users\<user>\...\Startup\ChatGPT Desktop Hotkey.lnk

Done. Alt + Space now toggles ChatGPT Desktop.
```

---

## 新增腳本時建議補充的欄位

之後 `scripts/` 若加入新工具，建議在本文件至少補這些欄位：

- **目的**：這支腳本解決什麼問題
- **參數**：必要與可選參數、預設值
- **行為**：會掃描哪些路徑、讀哪些檔、改哪些檔
- **安全性**：是否會覆寫檔案、是否有 backup、失敗時怎麼處理
- **範例**：最小可執行指令
- **預期輸出**：讓使用者知道成功/失敗長怎樣
- **限制**：已知不支援的格式或邊界條件

如果之後腳本數量變多，可以把本檔維持為總索引，再將每支腳本拆成獨立文件，例如：

- `scripts/remove-local-git-user.md`
- `scripts/some-future-script.md`

但在拆分之前，仍應保留這份 `scripts/SCRIPTS.md` 作為唯一入口。

[Back to top](#quick-navigation)

