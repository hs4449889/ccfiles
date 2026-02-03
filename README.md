# ccfiles

Claude Code用のカスタム設定・スクリプト集

## 機能

### 1. tmuxセッションごとの通知

tmuxセッションに応じて通知を出し分けます。

#### 通知タイプ

| タイプ | 用途 | 音 |
|--------|------|-----|
| `question` | Claudeが質問するとき | ロボットっぽいビープ音 |
| `attention` | 承認が必要なとき | ねえねえ音 |
| `complete` | タスク完了時 | ピロリン♪（ドミソ） |

#### セッション別カラー

tmuxセッション名のハッシュ値から12色のうち1色が自動割り当てされます。
複数のClaude Codeウィンドウを視覚的に区別できます。

```bash
# 通知テスト
./scripts/tmux-notify.sh test

# 色プレビュー
./scripts/tmux-notify.sh colors

# 個別の通知タイプをテスト
./scripts/tmux-notify.sh question
./scripts/tmux-notify.sh attention
./scripts/tmux-notify.sh complete
```

### 2. Gemini CLIを使った並列調査

調査タスクでは、テーマごとにGemini CLIへ並列で切り出して高品質な調査を実行します。

#### 使い方

`.claude/SKILLS.md` の設定により、Claude Codeは調査時に以下のように動作します：

1. 調査テーマを複数のサブテーマに分解
2. 各サブテーマをGemini CLIで並列実行
3. 結果を統合して包括的な回答を構築

#### カスタムエージェント

```
/agent gemini-researcher "調査したいテーマ"
```

## セットアップ

### 1. スクリプトに実行権限を付与

```bash
chmod +x scripts/tmux-notify.sh
```

### 2. 依存ツールのインストール（オプション）

#### macOS

```bash
# システムサウンドを使用するため追加インストール不要
```

#### Linux

```bash
# Ubuntu/Debian
sudo apt install sox libsox-fmt-all notify-send

# Arch Linux
sudo pacman -S sox libnotify
```

### 3. Gemini CLIのインストール

```bash
# npm経由でインストール
npm install -g @anthropic-ai/gemini-cli

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
│   ├── SKILLS.md           # Claude Codeのスキル定義
│   ├── settings.json       # hooks設定
│   └── agents/
│       └── gemini-researcher.md  # Gemini調査エージェント
├── scripts/
│   └── tmux-notify.sh      # tmux通知スクリプト
├── LICENSE
└── README.md
```

## License

MIT
