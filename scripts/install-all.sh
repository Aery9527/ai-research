#!/usr/bin/env bash
# Menu-driven installer for Claude Code CLI and Codex CLI.
# Windows counterpart: install-all.ps1 (also installs the PowerShell profile via
# tool/pwsh/install.ps1, item 3, and the desktop-app hotkey scripts via
# scripts/setup-cc-desktop-ahk.ps1 / setup-cx-desktop-ahk.ps1, items 5 and 6 —
# none of which apply on macOS/Linux).
#
# Selected items (comma-separated, e.g. "1,4") always run in the fixed order
# 1 -> 2 -> 3 -> 4 -> 5 -> 6 regardless of the order typed; leaving the input blank or
# entering 0 runs all of them. set -e means a failure in one selected item stops the rest.
#
# Usage: bash ./scripts/install-all.sh
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

printf '%s\n' '=========================================='
printf '%s\n' '   Install All'
printf '%s\n' '=========================================='
printf '\n'
printf '  [1] Claude Code CLI (install-cc)\n'
printf '  [2] Codex CLI (install-cx)\n'
printf '  [3] PowerShell 腳本 (install.ps1) - 僅適用 Windows，這裡會自動略過\n'
printf '  [4] 系統提示詞 (install-sys-prompt)\n'
printf '  [5] Claude Desktop 熱鍵 (setup-cc-desktop-ahk) - 僅適用 Windows，這裡會自動略過\n'
printf '  [6] ChatGPT Desktop 熱鍵 (setup-cx-desktop-ahk) - 僅適用 Windows，這裡會自動略過\n'
printf '\n'
printf '  [0] 全部安裝（預設）\n'
printf '\n'
printf '%s\n' '=========================================='

read -r -p '請輸入要安裝的項目編號，可用逗號分隔多選（例如 1,4；留空或輸入 0 = 全部安裝）: ' raw

trimmed="$(printf '%s' "$raw" | tr -d '[:space:]')"

selected="1 2 3 4 5 6"
if [[ -n "$trimmed" && "$trimmed" != "0" ]]; then
    IFS=',' read -r -a requested <<< "$trimmed"
    for key in "${requested[@]}"; do
        case "$key" in
            1|2|3|4|5|6) ;;
            *)
                printf 'ERROR: 無效的選項: %s\n' "$key" >&2
                exit 1
                ;;
        esac
    done
    selected=""
    for key in 1 2 3 4 5 6; do
        for r in "${requested[@]}"; do
            if [[ "$r" == "$key" ]]; then
                selected="$selected $key"
                break
            fi
        done
    done
fi

printf '\n'
for key in $selected; do
    case "$key" in
        1)
            printf '=== [1] Claude Code CLI ===\n'
            bash "$REPO_ROOT/cli-agents/claude-code/install-cc.sh"
            ;;
        2)
            printf '=== [2] Codex CLI ===\n'
            bash "$REPO_ROOT/cli-agents/codex/install-cx.sh"
            ;;
        3)
            printf '=== [3] PowerShell 腳本 ===\n'
            printf '  此項目僅適用於 Windows，Mac 版本自動略過。\n'
            ;;
        4)
            printf '=== [4] 系統提示詞 ===\n'
            bash "$REPO_ROOT/cli-agents/install-sys-prompt.sh"
            ;;
        5)
            printf '=== [5] Claude Desktop 熱鍵 ===\n'
            printf '  此項目僅適用於 Windows，Mac 版本自動略過。\n'
            ;;
        6)
            printf '=== [6] ChatGPT Desktop 熱鍵 ===\n'
            printf '  此項目僅適用於 Windows，Mac 版本自動略過。\n'
            ;;
    esac
    printf '\n'
done

printf '[OK] 全部完成\n'
