#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
custom_source="$SCRIPT_DIR/prompt-custom.md"
if (( $# )); then
    if [[ "$1" != '--custom-prompt' || $# != 2 || -z "$2" ]]; then
        printf '%s\n' 'ERROR: Usage: install-sys-prompt.sh [--custom-prompt FILE]' >&2
        exit 1
    fi
    case "$2" in
        /*) custom_source="$2" ;;
        *) custom_source="$SCRIPT_DIR/$2" ;;
    esac
fi

if [[ -z "${HOME:-}" ]]; then
    printf '%s\n' 'ERROR: HOME is not set.' >&2
    exit 1
fi

prompt_sources=("$SCRIPT_DIR/prompt-user.md" "$custom_source")
template_claude="$SCRIPT_DIR/claude-code/.claude/CLAUDE.md"
template_codex="$SCRIPT_DIR/codex/.codex/AGENTS.md"
template_copilot="$SCRIPT_DIR/github-copilot/.copilot/copilot-instructions.md"

for source in "${prompt_sources[@]}" "$template_claude" "$template_codex" "$template_copilot"; do
    if [[ ! -f "$source" || ! -r "$source" ]]; then
        printf 'ERROR: Source file not found or unreadable: %s\n' "$source" >&2
        exit 1
    fi
done

printf '%s\n' '=== Install common prompts ==='

target_claude="$HOME/.claude/CLAUDE.md"
target_codex="$HOME/.codex/AGENTS.md"
target_copilot="$HOME/.copilot/copilot-instructions.md"

mkdir -p "$(dirname "$target_claude")" "$(dirname "$target_codex")" "$(dirname "$target_copilot")"

backup_suffix=$(date +%y%m%d%H%M%S)

backup_if_exists() {
    local target="$1"
    if [[ -f "$target" ]]; then
        local backup="${target}_${backup_suffix}"
        mv -f "$target" "$backup"
        printf '  [Backup] %s -> %s\n' "$target" "$backup"
    fi
}

backup_if_exists "$target_claude"
cp -f "$template_claude" "$target_claude"
printf '  [OK] Template: %s\n' "$target_claude"
backup_if_exists "$target_codex"
cp -f "$template_codex" "$target_codex"
printf '  [OK] Template: %s\n' "$target_codex"
backup_if_exists "$target_copilot"
cp -f "$template_copilot" "$target_copilot"
printf '  [OK] Template: %s\n' "$target_copilot"

for target in "$target_claude" "$target_codex" "$target_copilot"; do
    for source in "${prompt_sources[@]}"; do
        printf '\n\n' >> "$target"
        cat "$source" >> "$target"
        printf '  [OK] %s: %s\n' "${source##*/}" "$target"
    done
done

printf '%s\n' 'Done.'
