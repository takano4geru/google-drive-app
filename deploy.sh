#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 GitHub Pages へのデプロイを開始します..."

# Gitリモートからユーザー名とリポジトリ名を自動取得
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

if [ -z "$REMOTE_URL" ]; then
  echo "❌ エラー: Gitのアクセス先（remote 'origin'）が設定されていません。"
  echo "先に以下のコマンドでGitHubリポジトリを設定してください："
  echo "  git remote add origin https://github.com/ユーザー名/リポジトリ名.git"
  exit 1
fi

# リポジトリ名とユーザー名を抽出
REPO_NAME=$(basename -s .git "$REMOTE_URL")

# SSH形式 (git@github.com:user/repo.git) と HTTPS形式 (https://github.com/user/repo.git) 両方に対応
if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/ ]]; then
  USER_NAME="${BASH_REMATCH[1]}"
else
  USER_NAME="your-username"
fi

echo "📦 検出されたリポジトリ: $USER_NAME/$REPO_NAME"

echo "🧹 古いビルドファイルをクリーンアップ中..."
flutter clean

echo "🛠️ Flutter Web アプリをビルド中 (base-href: /$REPO_NAME/)..."
flutter build web --base-href "/$REPO_NAME/"

echo "📂 ビルド出力フォルダ（build/web）に移動します..."
cd build/web

echo "🌱 一時的なGitリポジトリを初期化中..."
git init
git add .
git commit -m "Deploy to GitHub Pages"
git branch -M gh-pages

echo "📤 GitHub Pages (gh-pages ブランチ) へ強制プッシュ中..."
git push -f "$REMOTE_URL" gh-pages

echo "--------------------------------------------------"
echo "✅ デプロイが完了しました！"
echo "🌐 アプリのURL: https://$USER_NAME.github.io/$REPO_NAME/"
echo "※ 反映されるまで1〜2分程度かかる場合があります。"
echo "--------------------------------------------------"
