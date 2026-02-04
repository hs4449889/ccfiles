#!/bin/bash
# Claude Code 統合通知スクリプト
# 使用方法: notify.sh <event_type> [message]
# event_type: request, approve, complete, session-start, test

set -e

EXTENSIONS_DIR="$HOME/.claude/extensions"
CONFIG_FILE="$EXTENSIONS_DIR/config.json"
SOUNDS_DIR="$EXTENSIONS_DIR/sounds"
SESSIONS_DIR="$EXTENSIONS_DIR/last-sessions"
ICONS_CACHE_DIR="$EXTENSIONS_DIR/icons/cache"

# 色パレット（tmuxセッション名ごとに自動割り当て）
COLORS=(
    "#E53935"  # 赤
    "#1E88E5"  # 青
    "#43A047"  # 緑
    "#FB8C00"  # オレンジ
    "#8E24AA"  # 紫
    "#00ACC1"  # シアン
    "#FFB300"  # 黄
    "#6D4C41"  # 茶
    "#546E7A"  # グレー
    "#D81B60"  # ピンク
)

# イベントタイプを取得
EVENT_TYPE="${1:-test}"
CUSTOM_MESSAGE="${2:-}"

# 現在のプロジェクトディレクトリ
PROJECT_DIR=$(pwd)

# tmuxセッション名を取得
TMUX_SESSION=""
if [ -n "$TMUX" ]; then
    TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null)
fi

# tmuxセッション名から色付きアイコンを生成（キャッシュ付き）
get_session_icon() {
    local session_name="$1"

    if [ -z "$session_name" ]; then
        echo ""
        return
    fi

    # キャッシュディレクトリを作成
    mkdir -p "$ICONS_CACHE_DIR"

    # セッション名のハッシュから色インデックスを決定
    local hash=$(echo -n "$session_name" | md5)
    local hash_num=$((16#${hash:0:8}))
    local color_index=$((hash_num % ${#COLORS[@]}))
    local color="${COLORS[$color_index]}"

    # アイコンファイルパス
    local icon_file="$ICONS_CACHE_DIR/${session_name}.png"

    # キャッシュがなければ生成
    if [ ! -f "$icon_file" ]; then
        if command -v magick &> /dev/null; then
            # ImageMagick 7
            magick -size 64x64 xc:transparent \
                -fill "$color" -draw "circle 32,32 32,4" \
                "$icon_file" 2>/dev/null || true
        elif command -v convert &> /dev/null; then
            # ImageMagick 6
            convert -size 64x64 xc:transparent \
                -fill "$color" -draw "circle 32,32 32,4" \
                "$icon_file" 2>/dev/null || true
        fi
    fi

    if [ -f "$icon_file" ]; then
        echo "$icon_file"
    else
        echo ""
    fi
}

# config.jsonからプロジェクト設定を取得
get_project_config() {
    local project_dir="$1"
    local config_key="$2"

    if [ -f "$CONFIG_FILE" ]; then
        # プロジェクトパスで完全一致を検索
        local value=$(jq -r --arg dir "$project_dir" --arg key "$config_key" \
            '.projects[$dir][$key] // empty' "$CONFIG_FILE" 2>/dev/null)

        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return
        fi

        # 前方一致で検索
        local matched=$(jq -r --arg dir "$project_dir" \
            '[.projects | to_entries[] | select($dir | startswith(.key))] | sort_by(.key | length) | reverse | .[0].value' \
            "$CONFIG_FILE" 2>/dev/null)

        if [ -n "$matched" ] && [ "$matched" != "null" ]; then
            value=$(echo "$matched" | jq -r --arg key "$config_key" '.[$key] // empty' 2>/dev/null)
            if [ -n "$value" ] && [ "$value" != "null" ]; then
                echo "$value"
                return
            fi
        fi

        # デフォルト設定を使用
        jq -r --arg key "$config_key" '.default[$key] // empty' "$CONFIG_FILE" 2>/dev/null
    fi
}

# グローバル設定を取得
get_global_config() {
    local config_key="$1"
    local default_value="$2"

    if [ -f "$CONFIG_FILE" ]; then
        local value=$(jq -r --arg key "$config_key" '.[$key] // empty' "$CONFIG_FILE" 2>/dev/null)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return
        fi
    fi
    echo "$default_value"
}

# プロジェクト設定を取得
PROJECT_NAME=$(get_project_config "$PROJECT_DIR" "name")
PROJECT_ICON=$(get_project_config "$PROJECT_DIR" "icon")
GROUP_ID=$(get_project_config "$PROJECT_DIR" "groupId")

# 通知方法を取得（osc777, terminal-notifier, osascript, all）
NOTIFY_METHOD=$(get_global_config "notifyMethod" "all")

# デフォルト値
PROJECT_NAME="${PROJECT_NAME:-Claude Code}"
GROUP_ID="${GROUP_ID:-claude-default}"

# イベント別の設定
case "$EVENT_TYPE" in
    request)
        TITLE="対応依頼"
        MESSAGE="${CUSTOM_MESSAGE:-入力が必要です}"
        SOUND_FILE="$SOUNDS_DIR/request.aiff"
        ;;
    approve)
        TITLE="承認"
        MESSAGE="${CUSTOM_MESSAGE:-ツールが実行されました}"
        SOUND_FILE="$SOUNDS_DIR/approve.aiff"
        ;;
    complete)
        TITLE="完了"
        MESSAGE="${CUSTOM_MESSAGE:-処理が完了しました}"
        SOUND_FILE="$SOUNDS_DIR/complete.aiff"
        ;;
    session-start)
        # セッション情報を記録（標準入力からJSONを読み取る）
        if [ -t 0 ]; then
            # 標準入力がターミナルの場合（手動テスト時）
            SESSION_ID="manual-test-$(date +%s)"
        else
            # パイプ入力がある場合
            SESSION_INFO=$(cat)
            SESSION_ID=$(echo "$SESSION_INFO" | jq -r '.session_id // empty' 2>/dev/null)
        fi

        if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ]; then
            PROJECT_HASH=$(echo "$PROJECT_DIR" | md5 | cut -c1-8)
            mkdir -p "$SESSIONS_DIR"
            echo "$SESSION_ID|$PROJECT_DIR|$(date +%Y-%m-%d_%H:%M:%S)" >> "$SESSIONS_DIR/history.txt"
            echo "$SESSION_ID" > "$SESSIONS_DIR/$PROJECT_HASH.txt"
        fi
        # セッション記録のみ、通知は出さない
        exit 0
        ;;
    test)
        TITLE="テスト通知"
        MESSAGE="${CUSTOM_MESSAGE:-通知システムが正常に動作しています}"
        SOUND_FILE="$SOUNDS_DIR/complete.aiff"
        ;;
    *)
        TITLE="Claude Code"
        MESSAGE="${CUSTOM_MESSAGE:-$EVENT_TYPE}"
        SOUND_FILE=""
        ;;
esac

# 通知タイトルを構築
if [ -n "$TMUX_SESSION" ]; then
    FULL_TITLE="[$TMUX_SESSION] $TITLE - $PROJECT_NAME"
else
    FULL_TITLE="$TITLE - $PROJECT_NAME"
fi

# ===========================================
# 通知送信関数
# ===========================================

# OSC 777 通知（Ghostty/WezTerm対応）
send_osc777() {
    # OSC 777 形式: \e]777;notify;title;body\007
    # 終端子は \007 (BEL) を使用
    printf '\e]777;notify;%s;%s\007' "$FULL_TITLE" "$MESSAGE"
}

# OSC 9 通知（iTerm2対応）
send_osc9() {
    # OSC 9 形式: \e]9;message\e\\
    printf '\e]9;%s: %s\e\\' "$FULL_TITLE" "$MESSAGE"
}

# terminal-notifier通知
send_terminal_notifier() {
    if command -v terminal-notifier &> /dev/null; then
        local subtitle="$PROJECT_NAME"
        if [ -n "$TMUX_SESSION" ]; then
            subtitle="$PROJECT_NAME [$TMUX_SESSION]"
        fi
        local args=(
            -title "$TITLE"
            -subtitle "$subtitle"
            -message "$MESSAGE"
            -group "$GROUP_ID"
        )

        # tmuxセッション名から自動生成アイコンを取得
        local session_icon=""
        if [ -n "$TMUX_SESSION" ]; then
            session_icon=$(get_session_icon "$TMUX_SESSION")
        fi

        # アイコンの優先順位: プロジェクト指定 > セッション自動生成
        if [ -n "$PROJECT_ICON" ] && [ -f "$PROJECT_ICON" ]; then
            args+=(-contentImage "$PROJECT_ICON")
        elif [ -n "$session_icon" ] && [ -f "$session_icon" ]; then
            args+=(-contentImage "$session_icon")
        fi

        terminal-notifier "${args[@]}" 2>/dev/null || true
    fi
}

# osascript通知
send_osascript() {
    osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\" subtitle \"$PROJECT_NAME - $TITLE\"" 2>/dev/null || true
}

# ntfy通知（Ghosttyフォーカス中でもバナー表示される）
send_ntfy() {
    if command -v ntfy &> /dev/null; then
        ntfy -t "$FULL_TITLE" send "$MESSAGE" 2>/dev/null || true
    fi
}

# ===========================================
# 通知を送信
# ===========================================
case "$NOTIFY_METHOD" in
    osc777)
        send_osc777
        ;;
    osc9)
        send_osc9
        ;;
    terminal-notifier)
        send_terminal_notifier
        ;;
    osascript)
        send_osascript
        ;;
    ntfy)
        send_ntfy
        ;;
    sound-only|none)
        # 視覚通知なし、音声のみ
        ;;
    all|*)
        # OSC 777を優先（Ghostty/WezTerm）、フォールバックでterminal-notifier
        send_osc777
        send_terminal_notifier
        ;;
esac

# ===========================================
# 音声を再生（バックグラウンド）
# ===========================================
if [ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ]; then
    afplay "$SOUND_FILE" &
fi
