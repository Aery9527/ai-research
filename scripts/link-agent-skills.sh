#!/usr/bin/env bash
# 建立或移除 .claude/skills 到 .agents/skills 的本機 symlink。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_PATH="$REPO_ROOT/.agents/skills"
LINK_PATH="$REPO_ROOT/.claude/skills"

echo '=== Agent Skills Linker ==='
echo '  來源：.agents/skills；本機連結：.claude/skills'
echo '  [0] 取消'
echo '  [1] 建立或修復整個 skills 目錄的 symlink'
echo '  [3] 移除指向此專案 skills 的 symlink'
read -rp '請輸入選項 (0, 1, 3): ' choice

case "$choice" in
    0) echo '  [!] 已取消'; exit 0 ;;
    1|3) ;;
    *) echo 'ERROR: 無效選項；請選擇 0、1 或 3。' >&2; exit 1 ;;
esac

if [ -e "$LINK_PATH" ] && [ ! -L "$LINK_PATH" ]; then
    echo 'ERROR: .claude/skills 是實體目錄或檔案；請先保留內容並遷移到 .agents/skills。' >&2
    exit 1
fi

if [ "$choice" = 1 ]; then
    if [ ! -d "$SOURCE_PATH" ] || [ -L "$SOURCE_PATH" ]; then
        echo 'ERROR: .agents/skills 必須是存在的實體目錄；請先完成 skills 遷移。' >&2
        exit 1
    fi
    # 只移除 link 本身，保留其原有目標的內容。
    if [ -L "$LINK_PATH" ]; then
        rm -- "$LINK_PATH"
    fi
    mkdir -p "$REPO_ROOT/.claude"
    MSYS=winsymlinks:nativestrict CYGWIN=winsymlinks:nativestrict ln -s ../.agents/skills "$LINK_PATH"
    if [ ! -L "$LINK_PATH" ]; then
        echo 'ERROR: 此環境未建立真正的 symlink；請使用原生 Unix 環境或 Windows PowerShell 版本。' >&2
        exit 1
    fi
    echo '  [OK] .claude/skills -> .agents/skills'
elif [ ! -L "$LINK_PATH" ]; then
    echo '  [!] .claude/skills 不存在，無需移除'
else
    target="$(readlink "$LINK_PATH")"
    if [ "$target" != '../.agents/skills' ] && [ "$target" != "$SOURCE_PATH" ]; then
        echo 'ERROR: .claude/skills 指向其他位置，保留此連結。' >&2
        exit 1
    fi
    rm -- "$LINK_PATH"
    echo '  [OK] 已移除 .claude/skills 連結，來源內容保留'
fi
