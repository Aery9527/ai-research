# 環境注意事項

- 工作環境紀錄檔：`<absolute-repository-path>/cli-agents/prompt-custom_ch.md`。
  每個 `env/*` branch 必須將佔位內容改為該環境的完整絕對路徑，並在 [prompt-custom.md](prompt-custom.md) 設定對應英文路徑；嚴禁將機器專屬路徑放入 `main`。
  對照檔與安裝器必須以設定的紀錄檔所在目錄定位，嚴禁以目前工作目錄或已安裝的 user prompt 所在目錄定位。
- 使用者決定記錄工作環境問題時，必須使用已設定的紀錄檔與同目錄的英文對照檔。
  任一路徑未設定、仍含佔位內容、兩個設定路徑未指向這一對檔案，或任一檔案無法讀取時，必須先詢問使用者才能寫入。
  必須先讀取兩檔與紀錄所在 repo 的 agent 規則，確認目前 branch 為 `env/*`，再依該 repo 規範 fetch 並 merge 遠端 `main`。
  同步後，必須重新讀取兩檔才能修改。
- 必須將同一案例以英文記錄於 [prompt-custom.md](prompt-custom.md)，並以繁體中文記錄於 [prompt-custom_ch.md](prompt-custom_ch.md)，保持事實與指示等價；兩檔必須核對後一起 commit。
- 記錄後，必須在同一環境 branch commit 並 push 兩檔。push 成功後，Windows 必須執行該 repo 的 [prompt 安裝器](install-sys-prompt.ps1)，macOS/Linux 必須執行 [Bash 安裝器](install-sys-prompt.sh)，重新部署英文 prompt。同步、commit、push 或安裝受阻或失敗時，必須停下詢問使用者；嚴禁自動 stash、丟棄變更、解決衝突或 force-push。
- 使用者決定記錄專案經驗時，必須依目前專案的紀錄規範處理；若無規範，必須先建議做法，取得使用者決定後才能記錄。
