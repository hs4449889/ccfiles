# グローバル設定

## 通知システム

Hooksで `~/.claude/extensions/notify.sh` を呼び出し、terminal-notifierで通知。

### テスト
```bash
~/.claude/extensions/notify.sh test "メッセージ"
```

### 設定変更
`~/.claude/extensions/config.json` の `notifyMethod` を変更：
- `terminal-notifier` - macOS通知（現在）
- `sound-only` - 音声のみ
