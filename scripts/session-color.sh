#!/bin/bash
# Session Color Manager for Claude Code
# セッションごとにユニークな色を割り当てる

# =============================================================================
# 設定
# =============================================================================

# カラーパレット（かわいい色 + 見やすい色）
declare -A COLOR_PALETTE=(
    ["pink"]="#FF6B9D"
    ["purple"]="#9B59B6"
    ["sky"]="#3498DB"
    ["turquoise"]="#1ABC9C"
    ["orange"]="#F39C12"
    ["coral"]="#E74C3C"
    ["mint"]="#2ECC71"
    ["hotpink"]="#E91E63"
    ["lavender"]="#B39DDB"
    ["peach"]="#FFAB91"
    ["cyan"]="#00BCD4"
    ["lime"]="#CDDC39"
)

COLOR_NAMES=("pink" "purple" "sky" "turquoise" "orange" "coral" "mint" "hotpink" "lavender" "peach" "cyan" "lime")

# セッションカラー保存先
SESSION_COLOR_DIR="${HOME}/.claude/session-colors"
mkdir -p "$SESSION_COLOR_DIR"

# =============================================================================
# 関数
# =============================================================================

# セッションIDからハッシュを生成して色を決定
get_color_for_session() {
    local session_id="$1"

    if [[ -z "$session_id" ]]; then
        # セッションIDがない場合はランダム
        session_id="$$-$(date +%s)"
    fi

    # セッションIDのハッシュからインデックスを計算
    local hash=$(echo -n "$session_id" | md5sum | cut -c1-8)
    local decimal=$((16#$hash))
    local idx=$((decimal % ${#COLOR_NAMES[@]}))

    local color_name="${COLOR_NAMES[$idx]}"
    local color_hex="${COLOR_PALETTE[$color_name]}"

    echo "$color_name:$color_hex"
}

# セッションカラーを保存
save_session_color() {
    local session_id="$1"
    local color_info="$2"

    if [[ -n "$session_id" ]]; then
        echo "$color_info" > "${SESSION_COLOR_DIR}/${session_id}"
    fi
}

# セッションカラーを取得
load_session_color() {
    local session_id="$1"
    local color_file="${SESSION_COLOR_DIR}/${session_id}"

    if [[ -f "$color_file" ]]; then
        cat "$color_file"
    else
        local color_info=$(get_color_for_session "$session_id")
        save_session_color "$session_id" "$color_info"
        echo "$color_info"
    fi
}

# 色をANSIエスケープコードに変換
hex_to_ansi() {
    local hex="$1"
    hex="${hex#\#}"  # Remove # prefix

    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))

    echo "\033[38;2;${r};${g};${b}m"
}

# セッション開始時のウェルカムメッセージを表示
show_session_banner() {
    local session_id="$1"
    local color_info=$(load_session_color "$session_id")
    local color_name="${color_info%%:*}"
    local color_hex="${color_info##*:}"
    local ansi_color=$(hex_to_ansi "$color_hex")
    local reset="\033[0m"

    echo -e "${ansi_color}╔════════════════════════════════════════╗${reset}"
    echo -e "${ansi_color}║  🤖 Claude Code Session Started        ║${reset}"
    echo -e "${ansi_color}║  Session Color: ${color_name}                  ║${reset}"
    echo -e "${ansi_color}╚════════════════════════════════════════╝${reset}"
}

# 環境変数として色情報をエクスポート
export_session_color() {
    local session_id="$1"
    local color_info=$(load_session_color "$session_id")
    local color_name="${color_info%%:*}"
    local color_hex="${color_info##*:}"

    echo "export CLAUDE_SESSION_COLOR_NAME='$color_name'"
    echo "export CLAUDE_SESSION_COLOR_HEX='$color_hex'"
    echo "export CLAUDE_SESSION_ID='$session_id'"
}

# 古いセッションカラーファイルをクリーンアップ（7日以上前）
cleanup_old_sessions() {
    find "$SESSION_COLOR_DIR" -type f -mtime +7 -delete 2>/dev/null
}

# =============================================================================
# メイン
# =============================================================================

main() {
    local command="$1"
    shift

    case "$command" in
        init)
            # SessionStartフックで使用
            local session_id="${1:-$$}"
            export_session_color "$session_id"
            cleanup_old_sessions
            ;;
        show)
            # セッション情報を表示
            local session_id="${1:-$$}"
            show_session_banner "$session_id"
            ;;
        get)
            # 色情報のみ取得
            local session_id="${1:-$$}"
            load_session_color "$session_id"
            ;;
        list)
            # すべての色をリスト
            echo "Available colors:"
            for name in "${COLOR_NAMES[@]}"; do
                local hex="${COLOR_PALETTE[$name]}"
                local ansi=$(hex_to_ansi "$hex")
                echo -e "  ${ansi}██${reset} $name ($hex)"
            done
            ;;
        cleanup)
            # 古いセッションをクリーンアップ
            cleanup_old_sessions
            echo "Cleaned up old session color files."
            ;;
        help|--help|-h)
            cat << 'EOF'
Session Color Manager for Claude Code

Usage: session-color.sh <command> [session_id]

Commands:
    init [id]    セッション開始時に環境変数を設定（eval用）
    show [id]    セッションバナーを表示
    get [id]     セッションの色情報を取得
    list         利用可能な色の一覧
    cleanup      古いセッションファイルをクリーンアップ
    help         このヘルプを表示

Examples:
    eval $(session-color.sh init my-session-123)
    session-color.sh show my-session-123
    session-color.sh list

セッションIDを省略するとプロセスIDが使用されます。
EOF
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use 'session-color.sh help' for usage information."
            exit 1
            ;;
    esac
}

if [[ $# -eq 0 ]]; then
    main help
else
    main "$@"
fi
