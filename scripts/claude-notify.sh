#!/bin/bash
# Claude Code Notification Script
# かわいい通知音と色分け機能付き

# =============================================================================
# 設定
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_COLOR_FILE="/tmp/claude-session-color-$$"
SOUNDS_DIR="${SCRIPT_DIR}/sounds"

# セッションカラーパレット（かわいい色）
COLORS=(
    "#FF6B9D"  # ピンク
    "#9B59B6"  # パープル
    "#3498DB"  # スカイブルー
    "#1ABC9C"  # ターコイズ
    "#F39C12"  # オレンジ
    "#E74C3C"  # コーラル
    "#2ECC71"  # ミント
    "#E91E63"  # ホットピンク
)

# =============================================================================
# ヘルパー関数
# =============================================================================

# OSを検出
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        MINGW*|CYGWIN*|MSYS*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

# セッションカラーを取得または生成
get_session_color() {
    if [[ -f "$SESSION_COLOR_FILE" ]]; then
        cat "$SESSION_COLOR_FILE"
    else
        local idx=$((RANDOM % ${#COLORS[@]}))
        echo "${COLORS[$idx]}" > "$SESSION_COLOR_FILE"
        cat "$SESSION_COLOR_FILE"
    fi
}

# =============================================================================
# 音声再生関数
# =============================================================================

# ビープ音を使った簡易通知（依存関係なし）
play_beep() {
    local pattern="$1"
    case "$pattern" in
        question)
            # ロボットっぽい音：ピッ↑ピ↓ピッ↑
            printf '\a' && sleep 0.1 && printf '\a' && sleep 0.15 && printf '\a'
            ;;
        attention)
            # ねえねえ音：ピピッ、ピピッ
            printf '\a' && sleep 0.05 && printf '\a' && sleep 0.3
            printf '\a' && sleep 0.05 && printf '\a'
            ;;
        complete)
            # 完了音：ピロリン♪
            printf '\a' && sleep 0.1 && printf '\a' && sleep 0.1 && printf '\a'
            ;;
    esac
}

# Linux用音声再生
play_sound_linux() {
    local sound_type="$1"
    local sound_file=""

    case "$sound_type" in
        question)
            # システムサウンドを使用、なければビープ
            if command -v paplay &>/dev/null; then
                sound_file="/usr/share/sounds/freedesktop/stereo/dialog-question.oga"
                [[ -f "$sound_file" ]] && paplay "$sound_file" 2>/dev/null && return
                sound_file="/usr/share/sounds/freedesktop/stereo/message.oga"
                [[ -f "$sound_file" ]] && paplay "$sound_file" 2>/dev/null && return
            fi
            play_beep question
            ;;
        attention)
            # 承認要求用の音
            if command -v paplay &>/dev/null; then
                sound_file="/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
                [[ -f "$sound_file" ]] && paplay "$sound_file" 2>/dev/null && return
                sound_file="/usr/share/sounds/freedesktop/stereo/bell.oga"
                [[ -f "$sound_file" ]] && paplay "$sound_file" 2>/dev/null && return
            fi
            play_beep attention
            ;;
        complete)
            # 完了音
            if command -v paplay &>/dev/null; then
                sound_file="/usr/share/sounds/freedesktop/stereo/complete.oga"
                [[ -f "$sound_file" ]] && paplay "$sound_file" 2>/dev/null && return
                sound_file="/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"
                [[ -f "$sound_file" ]] && paplay "$sound_file" 2>/dev/null && return
            fi
            play_beep complete
            ;;
    esac
}

# macOS用音声再生
play_sound_macos() {
    local sound_type="$1"

    case "$sound_type" in
        question)
            # Submarine = ロボットっぽい
            afplay /System/Library/Sounds/Submarine.aiff 2>/dev/null || play_beep question
            ;;
        attention)
            # Tink x2 = ねえねえ
            afplay /System/Library/Sounds/Tink.aiff 2>/dev/null
            sleep 0.2
            afplay /System/Library/Sounds/Tink.aiff 2>/dev/null || play_beep attention
            ;;
        complete)
            # Glass = きれいな完了音
            afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || play_beep complete
            ;;
    esac
}

# Windows用音声再生
play_sound_windows() {
    local sound_type="$1"

    case "$sound_type" in
        question)
            powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\Windows\Media\Windows Notify System Generic.wav').PlaySync()" 2>/dev/null || play_beep question
            ;;
        attention)
            powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\Windows\Media\Windows Notify Email.wav').PlaySync()" 2>/dev/null || play_beep attention
            ;;
        complete)
            powershell.exe -Command "(New-Object Media.SoundPlayer 'C:\Windows\Media\Windows Notify Calendar.wav').PlaySync()" 2>/dev/null || play_beep complete
            ;;
    esac
}

# 音声再生メイン関数
play_sound() {
    local sound_type="$1"
    local os=$(detect_os)

    case "$os" in
        linux)   play_sound_linux "$sound_type" ;;
        macos)   play_sound_macos "$sound_type" ;;
        windows) play_sound_windows "$sound_type" ;;
        *)       play_beep "$sound_type" ;;
    esac
}

# =============================================================================
# 通知表示関数
# =============================================================================

# デスクトップ通知を表示
show_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"  # low, normal, critical
    local os=$(detect_os)
    local color=$(get_session_color)

    case "$os" in
        linux)
            if command -v notify-send &>/dev/null; then
                notify-send --urgency="$urgency" --app-name="Claude Code" \
                    --hint="string:fgcolor:$color" \
                    "$title" "$message" 2>/dev/null
            fi
            ;;
        macos)
            osascript -e "display notification \"$message\" with title \"$title\" subtitle \"Claude Code\"" 2>/dev/null
            ;;
        windows)
            powershell.exe -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null; \$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02); \$template.SelectSingleNode('//text[@id=1]').InnerText = '$title'; \$template.SelectSingleNode('//text[@id=2]').InnerText = '$message'; [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$template)" 2>/dev/null
            ;;
    esac
}

# =============================================================================
# メインコマンド
# =============================================================================

main() {
    local command="$1"
    shift

    case "$command" in
        question)
            # ロボットが質問してくるときの通知
            play_sound question
            show_notification "Claude Code" "質問があります" "normal"
            ;;
        attention|permission)
            # 承認が必要なときの通知（ねえねえ）
            play_sound attention
            show_notification "Claude Code" "確認が必要です" "critical"
            ;;
        complete|done)
            # 完了通知
            play_sound complete
            show_notification "Claude Code" "タスクが完了しました！" "low"
            ;;
        color)
            # 現在のセッションカラーを表示
            echo "Session Color: $(get_session_color)"
            ;;
        reset-color)
            # セッションカラーをリセット
            rm -f "$SESSION_COLOR_FILE"
            echo "Session color reset. New color: $(get_session_color)"
            ;;
        test)
            # すべての通知をテスト
            echo "Testing notifications..."
            echo "Session Color: $(get_session_color)"
            echo ""
            echo "1. Question sound..."
            play_sound question
            sleep 1
            echo "2. Attention sound..."
            play_sound attention
            sleep 1
            echo "3. Complete sound..."
            play_sound complete
            echo ""
            echo "Done!"
            ;;
        help|--help|-h)
            cat << 'EOF'
Claude Code Notification Script

Usage: claude-notify.sh <command>

Commands:
    question    ロボットが質問してくるときの通知音
    attention   承認が必要なときの通知音（ねえねえ）
    permission  同上（aliasです）
    complete    タスク完了時の通知音
    done        同上（aliasです）
    color       現在のセッションカラーを表示
    reset-color セッションカラーをリセット
    test        すべての通知をテスト
    help        このヘルプを表示

Examples:
    ./claude-notify.sh question    # 質問音を再生
    ./claude-notify.sh attention   # ねえねえ音を再生
    ./claude-notify.sh complete    # 完了音を再生
    ./claude-notify.sh test        # 全音テスト

セッションごとに異なる色が自動的に割り当てられます。
EOF
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use 'claude-notify.sh help' for usage information."
            exit 1
            ;;
    esac
}

# スクリプト実行
if [[ $# -eq 0 ]]; then
    main help
else
    main "$@"
fi
