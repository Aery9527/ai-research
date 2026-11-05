# 開發時全局環境變數設定
$env:AERY_TEST = "定義各種變數"

# 未指定紀錄檔時提醒 AI 先確認路徑，並保留呼叫端已有設定。
if ([string]::IsNullOrWhiteSpace($env:AGENT_ENV_NOTES_FILE)) {
    $env:AGENT_ENV_NOTES_FILE = '尚未設定：請先詢問使用者並設定工作環境經驗紀錄檔的完整路徑'
}
