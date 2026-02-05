# Render Deployment Check Skill

## Description
Renderのデプロイ状況を確認し、ログを取得してエラーがないかチェックする汎用スキル。

## Usage
```
/render-check
```

## Instructions

このスキルが呼び出されたら、以下の手順でRenderのデプロイ状況を確認してください。

### 0. 環境変数の確認

まず、現在のプロジェクトの `.env` ファイルから以下の変数が取得可能か確認:

- `RENDER_API_KEY` - Render APIキー（必須）
- `RENDER_SERVICE_ID` - RenderサービスID（必須）
- `RENDER_OWNER_ID` - RenderオーナーID（必須）

もし `.env` にこれらの変数がない場合は、CLAUDE.md やプロジェクト内の設定を探してください。
それでも見つからない場合は、ユーザーに確認してください。

### 1. Sub-agentでログ取得（トークン節約のため）

Task toolを使用して、haiku modelのsub-agentにログ取得を委託してください。
**重要**: `source` コマンドのパスは、現在の作業ディレクトリ（プロジェクトルート）の `.env` ファイルの絶対パスに置き換えてから渡すこと。

```
Task tool parameters:
- subagent_type: "Bash"
- model: "haiku"
- prompt: |
    Renderのログを取得して、デプロイ状況を確認してください。

    以下のコマンドを実行:
    ```bash
    source {プロジェクトルートの絶対パス}/.env && \
    curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
      "https://api.render.com/v1/logs?ownerId=$RENDER_OWNER_ID&resource=$RENDER_SERVICE_ID&limit=100&direction=backward" \
      | python3 -c "import json,sys; [print(l['message']) for l in reversed(json.load(sys.stdin).get('logs',[]))]"
    ```

    結果を以下の形式で報告:
    1. デプロイ状態: 成功/失敗/進行中
    2. 最新のログメッセージ（重要なもの5件）
    3. エラーがあれば詳細
```

### 2. 結果の報告

Sub-agentからの結果を元に、ユーザーに以下を報告:
- デプロイ状態
- サービスURL（CLAUDE.mdまたは.envから取得）
- Renderダッシュボード: `https://dashboard.render.com/web/<RENDER_SERVICE_ID>`
- エラーがあれば対処方法の提案

### エラー時の一般的な対処

- **Build failed**: requirements.txt / package.json の依存関係を確認
- **Application startup failed**: 環境変数の設定を確認
- **Health check failed**: ヘルスチェックエンドポイントの応答を確認
- **Out of memory**: プランのアップグレードまたはメモリ使用量の最適化を検討

### 必要な.env変数のテンプレート

プロジェクトでこのスキルを使うには、`.env` に以下を追加:
```
RENDER_API_KEY=rnd_xxxxxxxxxxxx
RENDER_SERVICE_ID=srv-xxxxxxxxxxxx
RENDER_OWNER_ID=tea-xxxxxxxxxxxx
```
