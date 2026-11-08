# 環境注意事項

- 工作環境紀錄檔：`<absolute-recording-repository-path>/prompt-custom_ch.md`。
  每個 private `env/*` branch 必須設定自己的完整中文絕對路徑，並在 [prompt-custom.md](prompt-custom.md) 設定對應英文路徑；嚴禁將機器專屬路徑放入 `main` 或公開來源 repo。
  對照檔、`ai-research` submodule 與根目錄 wrapper 必須以設定紀錄檔所在目錄定位，嚴禁以目前工作目錄或已安裝 prompt 定位。
- 使用者決定記錄工作環境問題時，必須先讀取兩份語言檔與紀錄 repo 的 agent 規則，並在任何修改前確認 private `env/*` branch、repo/index/submodule 都乾淨。
  任一路徑未設定、含佔位內容、未指向這一對檔案或無法讀取時，必須先詢問使用者才能寫入。
- 必須在紀錄 repo 的 `ai-research` submodule 內 fetch 公開 `main`，再將 checkout 前進至本次取得的 commit。嚴禁將公開 Git 歷史 merge 到 private 父 repo，也不例行 merge private `main`。
  pin 有變時，必須先審查並以獨立同步 commit 只提交 `ai-research` gitlink，再修改紀錄。pin 必須在公開 main 上前進，並保留外部 custom 安裝參數支援。嚴禁初始化巢狀 submodule；已初始化的巢狀 submodule 或非預期未提交內容，必須停下由使用者決定，嚴禁自動清理。
  同步後必須重新讀取兩份語言檔。
- 必須將同一案例以英文記錄於 [prompt-custom.md](prompt-custom.md)，並以繁體中文記錄於 [prompt-custom_ch.md](prompt-custom_ch.md)。必須審查事實與指示等價後，一起 commit 兩檔，不得混入其他修改。
- 必須將同步與紀錄 commits push 至同一 private 環境 branch。push 成功後，必須執行根目錄的 [Windows wrapper](install-sys-prompt.ps1)或 [macOS/Linux wrapper](install-sys-prompt.sh)，合併部署 submodule 的工具範本、共用 user prompt 與此 repo 的英文 custom。
  同步、審查、commit、push 或部署失敗時，必須停下詢問使用者；嚴禁自動 stash、丟棄變更、解決衝突或 force-push。
- 使用者決定記錄專案經驗時，必須依目前專案的紀錄規範處理；若無規範，必須先建議做法，取得使用者決定後才能記錄。
