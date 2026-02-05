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

## dotfiles管理（ccfiles）

`~/.claude` の設定ファイルは `/Users/itoukoicha/Desktop/WORKDIR/ccfiles` リポジトリで管理。

シンボリックリンク構成:
- `~/.claude/CLAUDE.md` → `ccfiles/CLAUDE.md`
- `~/.claude/extensions/` → `ccfiles/extensions/`
- `~/.claude/skills/` → `ccfiles/skills/`

**ルール**: グローバルの `skills/`、`extensions/`、`CLAUDE.md` を追加・変更した場合は、ccfilesリポジトリ（`/Users/itoukoicha/Desktop/WORKDIR/ccfiles`）でコミットすること。

## グローバルSkills

| コマンド | 説明 |
|----------|------|
| `/render-check` | Renderのデプロイログを取得・検証（汎用版） |

### /render-check の前提条件
プロジェクトの `.env` に以下が必要:
```
RENDER_API_KEY=rnd_xxxxxxxxxxxx
RENDER_SERVICE_ID=srv-xxxxxxxxxxxx
RENDER_OWNER_ID=tea-xxxxxxxxxxxx
```
