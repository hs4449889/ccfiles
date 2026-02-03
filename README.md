# ccfiles

Claude Code用のカスタム設定・スクリプト集

## 機能

### 1. 通知音（3種類）

Claudeの各種イベントで、かわいい通知音を鳴らします。

| タイプ | コマンド | 用途 | 音 |
|--------|---------|------|-----|
| `question` | `./scripts/claude-notify.sh question` | Claudeが質問するとき | ロボットっぽいビープ音 |
| `attention` | `./scripts/claude-notify.sh attention` | 承認が必要なとき | ねえねえ音 |
| `complete` | `./scripts/claude-notify.sh complete` | タスク完了時 | ピロリン♪ |

```bash
# すべての通知音をテスト
./scripts/claude-notify.sh test
```

### 2. セッションカラー

セッションごとにピンク、パープル、ミントなど12色からランダムに色を割り当て。
複数のClaude Codeウィンドウを視覚的に区別できます。

```bash
# セッションバナーを表示
./scripts/session-color.sh show

# 利用可能な色の一覧
./scripts/session-color.sh list

# 環境変数として色情報をエクスポート
eval $(./scripts/session-color.sh init my-session-id)
```

### 3. tmuxセッションごとの通知

tmuxセッションに応じて通知を出し分けます。セッション名のハッシュ値から自動的に12色のうち1色が割り当てられます。

```bash
# 通知テスト（全タイプ）
./scripts/tmux-notify.sh test

# 色プレビュー
./scripts/tmux-notify.sh colors

# 個別の通知タイプ
./scripts/tmux-notify.sh question
./scripts/tmux-notify.sh attention
./scripts/tmux-notify.sh complete
```

### 4. Gemini CLIを使った並列調査

調査タスクでは、テーマごとにGemini CLIへ並列で切り出して高品質な調査を実行します。

#### カスタムエージェント

```
/agent gemini-researcher "調査したいテーマ"
```

#### 並列調査の例

```bash
# 3つのテーマを並列で調査
gemini -p "テーマA について詳しく調査してください" > /tmp/research_a.md &
gemini -p "テーマB について詳しく調査してください" > /tmp/research_b.md &
gemini -p "テーマC について詳しく調査してください" > /tmp/research_c.md &
wait

# 結果を統合
cat /tmp/research_*.md
```

`.claude/SKILLS.md` の設定により、Claude Codeは調査時に以下のように動作します：

1. 調査テーマを複数のサブテーマに分解
2. 各サブテーマをGemini CLIで並列実行
3. 結果を統合して包括的な回答を構築

## セットアップ

### 1. スクリプトに実行権限を付与

```bash
chmod +x scripts/*.sh
```

### 2. 依存ツールのインストール（オプション）

#### macOS

```bash
# システムサウンドを使用するため追加インストール不要
```

#### Linux

```bash
# Ubuntu/Debian
sudo apt install sox libsox-fmt-all libnotify-bin

# Arch Linux
sudo pacman -S sox libnotify
```

### 3. Gemini CLIのインストール

```bash
# npm経由でインストール
npm install -g @google/generative-ai-cli

# または直接インストール
curl -fsSL https://gemini.google.com/cli/install.sh | bash
```

### 4. Claude Codeへの設定適用

このリポジトリを `~/.claude/` にコピーするか、シンボリックリンクを作成：

```bash
# 方法1: コピー
cp -r .claude/* ~/.claude/

# 方法2: シンボリックリンク
ln -sf $(pwd)/.claude/SKILLS.md ~/.claude/SKILLS.md
ln -sf $(pwd)/.claude/settings.json ~/.claude/settings.json
ln -sf $(pwd)/.claude/agents ~/.claude/agents
```

## ファイル構成

```
.
├── .claude/
│   ├── SKILLS.md                 # Claude Codeのスキル定義（Gemini CLI並列調査）
│   ├── settings.json             # hooks設定（通知トリガー）
│   └── agents/
│       └── gemini-researcher.md  # Gemini調査エージェント
├── scripts/
│   ├── claude-notify.sh          # 通知音スクリプト
│   ├── session-color.sh          # セッションカラー管理
│   └── tmux-notify.sh            # tmux通知スクリプト
├── LICENSE
└── README.md
```

## hooks設定

`.claude/settings.json` で以下のhooksが設定されています：

| イベント | トリガー | 動作 |
|----------|----------|------|
| SessionStart | セッション開始時 | セッションカラー表示 |
| Notification (permission_prompt) | 承認が必要なとき | attention音を再生 |
| Notification (elicitation_dialog) | Claudeが質問するとき | question音を再生 |
| PostToolUse (Bash) | Bashコマンド実行後 | tmux通知 |
| Stop | タスク完了時 | complete音 + tmux通知 |

## License

MIT
