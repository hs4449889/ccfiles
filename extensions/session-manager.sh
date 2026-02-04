#!/bin/bash
# Claude Code セッション管理スクリプト
# 使用方法: session-manager.sh <command>
# command: list, recent, project

EXTENSIONS_DIR="$HOME/.claude/extensions"
SESSIONS_DIR="$EXTENSIONS_DIR/last-sessions"
HISTORY_FILE="$SESSIONS_DIR/history.txt"

# コマンドを取得
COMMAND="${1:-list}"

case "$COMMAND" in
    list)
        echo "=== 最近のセッション ==="
        echo ""
        if [ -f "$HISTORY_FILE" ]; then
            tail -20 "$HISTORY_FILE" | tac | while IFS='|' read -r session_id project_dir timestamp; do
                if [ -n "$session_id" ]; then
                    project_name=$(basename "$project_dir")
                    echo "[$timestamp] $project_name"
                    echo "  ディレクトリ: $project_dir"
                    echo "  再開: claude --resume $session_id"
                    echo ""
                fi
            done
        else
            echo "セッション履歴がありません。"
            echo "Claude Codeでセッションを開始すると、ここに表示されます。"
        fi
        echo ""
        echo "Tips:"
        echo "  - 最後のセッションを再開: claude --continue"
        echo "  - 特定のセッションを再開: claude --resume <session_id>"
        ;;

    recent)
        # 最新のセッションIDを取得
        if [ -f "$HISTORY_FILE" ]; then
            tail -1 "$HISTORY_FILE" | cut -d'|' -f1
        fi
        ;;

    project)
        # 現在のプロジェクトの最終セッションを取得
        PROJECT_DIR=$(pwd)
        PROJECT_HASH=$(echo "$PROJECT_DIR" | md5 | cut -c1-8)
        SESSION_FILE="$SESSIONS_DIR/$PROJECT_HASH.txt"

        if [ -f "$SESSION_FILE" ]; then
            SESSION_ID=$(cat "$SESSION_FILE")
            echo "プロジェクト: $PROJECT_DIR"
            echo "最終セッション: $SESSION_ID"
            echo ""
            echo "再開するには:"
            echo "  claude --resume $SESSION_ID"
        else
            echo "このプロジェクトのセッション履歴がありません。"
        fi
        ;;

    clear)
        # 履歴をクリア
        read -p "セッション履歴をクリアしますか？ (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            rm -f "$HISTORY_FILE"
            rm -f "$SESSIONS_DIR"/*.txt
            echo "セッション履歴をクリアしました。"
        else
            echo "キャンセルしました。"
        fi
        ;;

    help|*)
        echo "Claude Code セッション管理"
        echo ""
        echo "使用方法: session-manager.sh <command>"
        echo ""
        echo "コマンド:"
        echo "  list     最近のセッション一覧を表示（デフォルト）"
        echo "  recent   最新のセッションIDを表示"
        echo "  project  現在のプロジェクトの最終セッションを表示"
        echo "  clear    セッション履歴をクリア"
        echo "  help     このヘルプを表示"
        ;;
esac
