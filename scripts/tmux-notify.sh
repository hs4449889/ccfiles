#!/bin/bash
# tmux-notify.sh - tmuxセッションごとに通知を出し分けるスクリプト
# 使用方法: ./tmux-notify.sh <notification_type>
# notification_type: question | attention | complete

set -e

# --- 設定 ---
NOTIFICATION_TYPE="${1:-complete}"

# 通知タイプごとの設定（絵文字・色・音）
declare -A NOTIFY_EMOJI=(
    ["question"]="🤖"
    ["attention"]="👋"
    ["complete"]="✅"
)

declare -A NOTIFY_MESSAGE=(
    ["question"]="Claude has a question"
    ["attention"]="Claude needs your attention"
    ["complete"]="Claude completed the task"
)

# 音の周波数設定（Hzと長さms）
declare -A NOTIFY_FREQ=(
    ["question"]="800 100 600 100 800 100"      # ロボットっぽいビープ音
    ["attention"]="1000 150 1200 150 1000 150"  # ねえねえ音
    ["complete"]="523 100 659 100 784 150"      # ピロリン♪（ドミソ）
)

# --- tmuxセッション検出 ---
get_tmux_session() {
    if [[ -n "$TMUX" ]]; then
        tmux display-message -p '#S'
    else
        echo "default"
    fi
}

# --- セッションごとの色を取得 ---
get_session_color() {
    local session_name="$1"
    # セッション名のハッシュから色を決定
    local colors=(
        "#FF6B9D"  # ピンク
        "#A855F7"  # パープル
        "#06B6D4"  # シアン
        "#10B981"  # ミント
        "#F59E0B"  # オレンジ
        "#EF4444"  # レッド
        "#3B82F6"  # ブルー
        "#8B5CF6"  # バイオレット
        "#EC4899"  # マゼンタ
        "#14B8A6"  # ティール
        "#F97316"  # ディープオレンジ
        "#84CC16"  # ライム
    )
    local hash=$(echo -n "$session_name" | cksum | cut -d' ' -f1)
    local index=$((hash % ${#colors[@]}))
    echo "${colors[$index]}"
}

# --- 音を鳴らす ---
play_sound() {
    local type="$1"
    local freqs="${NOTIFY_FREQ[$type]}"

    # beepコマンドが利用可能な場合
    if command -v beep &> /dev/null; then
        local args=()
        for freq in $freqs; do
            if [[ ${#args[@]} -eq 0 ]]; then
                args+=("-f" "$freq")
            else
                args+=("-n" "-f" "$freq")
            fi
        done
        beep "${args[@]}" 2>/dev/null || true
    # macOSの場合
    elif command -v afplay &> /dev/null; then
        # システムサウンドを使用
        case "$type" in
            question)
                afplay /System/Library/Sounds/Funk.aiff 2>/dev/null || true
                ;;
            attention)
                afplay /System/Library/Sounds/Ping.aiff 2>/dev/null || true
                ;;
            complete)
                afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
                ;;
        esac
    # PulseAudioが利用可能な場合
    elif command -v paplay &> /dev/null; then
        # 一時的なWAVファイルを生成して再生
        generate_and_play_tone "$type"
    # Linuxのspd-sayを使用（音声合成）
    elif command -v spd-say &> /dev/null; then
        spd-say -w "${NOTIFY_MESSAGE[$type]}" 2>/dev/null || true
    fi
}

# --- PulseAudio用のトーン生成 ---
generate_and_play_tone() {
    local type="$1"

    # sox/playコマンドが使える場合
    if command -v play &> /dev/null; then
        case "$type" in
            question)
                play -n synth 0.1 sine 800 synth 0.1 sine 600 synth 0.1 sine 800 2>/dev/null || true
                ;;
            attention)
                play -n synth 0.15 sine 1000 synth 0.15 sine 1200 synth 0.15 sine 1000 2>/dev/null || true
                ;;
            complete)
                play -n synth 0.1 sine 523 synth 0.1 sine 659 synth 0.15 sine 784 2>/dev/null || true
                ;;
        esac
    fi
}

# --- tmuxステータスバーに通知表示 ---
show_tmux_notification() {
    local session_name="$1"
    local type="$2"
    local color="$3"
    local emoji="${NOTIFY_EMOJI[$type]}"
    local message="${NOTIFY_MESSAGE[$type]}"

    if [[ -n "$TMUX" ]]; then
        # tmuxのステータスバーにメッセージを表示
        tmux display-message -d 3000 "$emoji $message [$session_name]"

        # セッションの色でペインボーダーを一時的に変更
        tmux select-pane -P "bg=default,fg=$color"

        # 3秒後に元に戻す（バックグラウンドで）
        (sleep 3 && tmux select-pane -P "bg=default,fg=default") &
    fi
}

# --- デスクトップ通知を送信 ---
send_desktop_notification() {
    local session_name="$1"
    local type="$2"
    local emoji="${NOTIFY_EMOJI[$type]}"
    local message="${NOTIFY_MESSAGE[$type]}"
    local title="Claude Code [$session_name]"

    # macOS
    if command -v osascript &> /dev/null; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"default\"" 2>/dev/null || true
    # Linux (notify-send)
    elif command -v notify-send &> /dev/null; then
        local urgency="normal"
        [[ "$type" == "attention" ]] && urgency="critical"
        notify-send -u "$urgency" "$title" "$emoji $message" 2>/dev/null || true
    fi
}

# --- ターミナルベルを鳴らす ---
ring_terminal_bell() {
    printf '\a'
}

# --- メイン処理 ---
main() {
    local session_name=$(get_tmux_session)
    local color=$(get_session_color "$session_name")

    echo "Session: $session_name"
    echo "Color: $color"
    echo "Type: $NOTIFICATION_TYPE"

    # 通知を実行
    ring_terminal_bell
    play_sound "$NOTIFICATION_TYPE"
    show_tmux_notification "$session_name" "$NOTIFICATION_TYPE" "$color"
    send_desktop_notification "$session_name" "$NOTIFICATION_TYPE"
}

# テストモード
if [[ "$1" == "test" ]]; then
    echo "Testing all notification types..."
    for type in question attention complete; do
        echo ""
        echo "=== Testing: $type ==="
        NOTIFICATION_TYPE="$type"
        main
        sleep 1
    done
    exit 0
fi

# 色表示モード
if [[ "$1" == "colors" ]]; then
    echo "Session color preview:"
    for session in main dev test work project-a project-b; do
        color=$(get_session_color "$session")
        echo -e "\033[38;2;$((16#${color:1:2}));$((16#${color:3:2}));$((16#${color:5:2}))m● $session: $color\033[0m"
    done
    exit 0
fi

main
