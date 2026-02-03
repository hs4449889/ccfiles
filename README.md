# ccfiles

Claude Codeのカスタマイズ設定集 - 通知音、カスタムエージェント、セッション管理

## 機能

### 1. かわいい通知音

Claude Codeの動作に合わせた3種類の通知音:

| イベント | 音の雰囲気 | 説明 |
|---------|-----------|------|
| `question` | ロボットっぽい音 | Claudeが質問してくるとき |
| `attention` | ねえねえ | 承認が必要なとき |
| `complete` | ピロリン♪ | タスク完了時 |

### 2. セッションカラー

セッションごとに異なる色が自動的に割り当てられます。複数のClaude Codeセッションを開いているときに視覚的に区別できます。

**利用可能な色:**
- ピンク、パープル、スカイブルー、ターコイズ
- オレンジ、コーラル、ミント、ホットピンク
- ラベンダー、ピーチ、シアン、ライム

### 3. Gemini CLI調査エージェント

Claude CodeからGemini CLIを使って調査タスクを実行できるカスタムサブエージェント。

```
/agents gemini-researcher
```

## セットアップ

### 1. リポジトリをクローン

```bash
git clone https://github.com/hs4449889/ccfiles.git
cd ccfiles
```

### 2. スクリプトの実行権限を確認

```bash
chmod +x scripts/claude-notify.sh
chmod +x scripts/session-color.sh
```

### 3. 通知音のテスト

```bash
./scripts/claude-notify.sh test
```

### 4. Claude Codeの設定をコピー（オプション）

このリポジトリをそのままClaude Codeで使うか、設定ファイルを他のプロジェクトにコピーします:

```bash
# .claudeディレクトリをコピー
cp -r .claude ~/your-project/

# scriptsディレクトリもコピー
cp -r scripts ~/your-project/
```

## 依存関係

### Linux

通知音の再生には以下のいずれかが必要です:

```bash
# PulseAudio (推奨)
sudo apt install pulseaudio-utils

# デスクトップ通知
sudo apt install libnotify-bin
```

### macOS

追加のインストールは不要です（`afplay`と`osascript`を使用）。

### Windows (WSL/Git Bash)

PowerShellを通じてシステムサウンドを再生します。

## ファイル構成

```
ccfiles/
├── .claude/
│   ├── agents/
│   │   └── gemini-researcher.md  # Gemini CLI調査エージェント
│   └── settings.json             # Hooks設定
├── scripts/
│   ├── claude-notify.sh          # 通知音スクリプト
│   └── session-color.sh          # セッションカラー管理
├── LICENSE
└── README.md
```

## Hooks設定

`.claude/settings.json`で以下のイベントにフックを設定しています:

| イベント | 動作 |
|---------|------|
| `SessionStart` | セッションカラーを表示 |
| `Notification (permission_prompt)` | 承認要求音を再生 |
| `Notification (elicitation_dialog)` | 質問音を再生 |
| `Stop` | 完了音を再生 |

## カスタマイズ

### 通知音を変更する

`scripts/claude-notify.sh`を編集して、好みのサウンドファイルやシステムサウンドに変更できます。

### 色を追加する

`scripts/session-color.sh`の`COLOR_PALETTE`に新しい色を追加できます。

## Gemini CLI エージェントの使用方法

Gemini CLIがインストールされていることを確認してください:

```bash
# Gemini CLIのインストール（要Node.js）
npm install -g @anthropic/gemini-cli
# または
pip install google-generativeai
```

Claude Codeで調査タスクを依頼:

```
/agents gemini-researcher "最新のReact 19の機能について調べて"
```

## License

MIT License
