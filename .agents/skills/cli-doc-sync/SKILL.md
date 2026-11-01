---
name: cli-doc-sync
description: >-
  同步 CLI 參考文件與官方文件。當使用者提到「同步 CLI 文件」、「更新 CLI 參考」、
  「檢查 CLI 有沒有更新」、「cc-cli 對比官方」、「gc-cli 更新」、「codex-cli 更新」，或任何涉及將
  CLI 參考 Markdown 與官方文件對齊的需求時觸發。
---

# CLI Doc Sync

從官方文件抓取最新 CLI 參考資訊，與本地 Markdown 做結構化差異比對，補缺、刪多、更新描述，並維護目標文件中的 managed summary section。

## Tools

### `fetch_docs.py`

- 位置：[fetch_docs.py](fetch_docs.py)
- 首次使用可安裝依賴：`pip install requests markdownify`
- 列出可用目標：`python .agents/skills/cli-doc-sync/fetch_docs.py --list`
- 抓取目標：
  - `python .agents/skills/cli-doc-sync/fetch_docs.py claude-code`
  - `python .agents/skills/cli-doc-sync/fetch_docs.py github-copilot`
  - `python .agents/skills/cli-doc-sync/fetch_docs.py codex-cli`
- 抓取單一 URL：`python .agents/skills/cli-doc-sync/fetch_docs.py --url "https://..."`

### JSON Output Contract

- `target` — 目標名稱。
- `md_path` — 本地 Markdown 路徑。
- `fetched_at` — 抓取時間。
- `sources` — 來源陣列。
- 每個 source 若成功，會有 `url`、`label`、`content_md`。
- 每個 source 若失敗，會有 `error`，而不是 `content_md`。

## Workflow

1. 選擇目標。如果使用者未指定，列出可用目標並要求選擇。
2. 執行抓取。用 Bash 執行 `fetch_docs.py <target>`，取得 JSON 輸出，並確認所有 source 都成功。
3. 讀取現有 Markdown。用 JSON 內的 `md_path` 讀取目標檔，並定位 `## 更新時間與差異總結` 章節。
4. 解析差異。以 H2/H3 區段分隔，並以每個表格或條列區段的識別符作為比對錨點。識別符通常是 flag 名、command 名、快捷鍵或 slash command 名稱。
5. 產生差異報告。必須分成缺少項目、多出項目、描述可能過時，以及無變更摘要。
6. 等待使用者確認。嚴禁在未確認前直接修改文件。
7. 獲得確認後更新目標文件，並同步刷新 `## 更新時間與差異總結` 章節。

## Difference Classes

- 缺少：官方有，本地文件沒有。必須列入報告，確認後新增。
- 多出：本地文件有，官方沒有。必須列入報告，但嚴禁自動刪除；必須等待使用者決定。
- 描述過時：兩邊都有相同識別符，但官方語意與本地中文描述不一致。必須列出舊說明與官方說明，再等待確認後更新。
- 無變更：官方與本地一致。可在報告中只做總量摘要。

## Comparison Rules

- 比對必須以識別符為準，嚴禁直接把中英文整段文字做字面比對。
- 解析識別符時，必須去除 backtick 與多餘空白，做正規化後再比對。
- 若判斷為描述過時，必須基於語意，而不是字面差異。
- `## 更新時間與差異總結` 是 skill-managed content。每次實際同步後都必須更新。

## Reporting Format Requirements

- 報告標題必須包含目標工具名稱。
- 報告必須包含比對日期與來源 URL。
- 報告必須分開列出缺少項目、多出項目、描述可能過時、無變更。
- 報告必須額外給出 2 到 4 點「建議更新到文件的更新摘要」。

## Update Rules

- 新增項目時，必須插入到對應 section，維持既有欄位語意與詳細程度。
- 新增或更新描述時，必須翻譯為繁體中文；flag、command、model、tool、檔名、路徑等專有術語維持英文。
- 移除項目時，嚴禁自動刪除；只有在使用者明確確認後才能移除。
- 只要本次同步完成，就必須更新目標 md 內的 `## 更新時間與差異總結` 章節。

## Managed Summary Section Rules

- 每個目標 md 都必須有 `## 更新時間與差異總結`。
- 預設位置是開頭 metadata 區塊之後、主要參考章節之前。
- 此章節至少必須包含：
  - `更新時間`
  - `比較基準`
  - `差異摘要`
- 若本次與上一版比對後沒有實質內容變更，仍必須更新時間，並明寫「本次與上一版比對後無實質差異，僅重新確認官方文件仍一致」。

## Protected Content

- 嚴禁修改目標 md 開頭的安裝、更新、來源 metadata 區塊。
- 嚴禁修改使用者自行加入的提示、備註或散文段落，除非使用者明確要求。
- `## 更新時間與差異總結` 是唯一例外；它是此 skill 管理的區塊，可依同步結果更新。

## Structure Preservation Rules

- 必須保留既有 H2/H3 階層與排列順序。
- 必須保留既有欄位語意；若原文件使用表格，更新時保持該 section 的結構風格一致。
- 嚴禁重新格式化未變更內容。

## Target Configuration

- 工具清單定義在 [targets.json](targets.json)。
- 新增工具時，只需在 [targets.json](targets.json) 新增一筆 entry。
- 目前支援的目標：
  - `claude-code` -> [`cli-agents/claude-code/cc-cli.md`](../../../cli-agents/claude-code/cc-cli.md) -> 4 個來源 URL。
  - `github-copilot` -> [`cli-agents/github-copilot/gc-cli.md`](../../../cli-agents/github-copilot/gc-cli.md) -> 2 個來源 URL。
- `codex-cli` -> [`cli-agents/codex/cx-cli.md`](../../../cli-agents/codex/cx-cli.md) -> 5 個來源 URL。

## Quality Checklist

- 所有來源 URL 都成功抓取，JSON 中沒有 `error` 欄位。
- 差異報告已呈現給使用者並獲得確認。
- 新增項目已翻譯為繁體中文，專有術語維持英文。
- 沒有動到使用者自訂的備註或額外內容。
- 目標 md 的 `## 更新時間與差異總結` 已更新，且內容與本次差異報告一致。
- 已提醒使用者官方文件可能遺漏的 beta flag 或實驗功能。
