# CloudSync Docs

Google Drive とリアルタイム同期する、オフライン対応のメモ・ドキュメント管理 Flutter Web/Mobile アプリケーションです。

## 概要

本アプリは、Google アカウントでログインし、ユーザーの Google Drive 内に作成される `"CloudSync Docs"` というフォルダーとメモやドキュメントを同期するアプリケーションです。
オフラインファーストの設計になっており、インターネット接続が途切れた状態でもローカルに保存（キャッシュ）されたドキュメントを閲覧することができます。

### 主な特徴

- **セキュアな Google Drive 同期**:
  - `drive.file` スコープを使用し、アプリが作成したファイルおよびフォルダ（`CloudSync Docs`）のみにアクセスします。他の Google Drive 内のファイルへの読み書きは行わないため安心です。
- **オフラインファースト (ローカルキャッシュ)**:
  - オンライン中に取得・作成したドキュメントは、ローカルの `SharedPreferences` を用いて JSON 形式で自動キャッシュされます。
  - インターネットがない環境でアプリを起動した場合でも、「オフラインで続行 (Continue Offline)」ボタンから、ログインをスキップしてローカルキャッシュされたデータを読み取り専用モードで確認できます。
- **自動セッショントークン更新**:
  - トークンの有効期限切れ（401/403エラー）が発生した場合、自動的に OAuth トークンをリフレッシュして処理をリトライするため、ユーザーにサインアウトを求めることなく安定した動作を提供します。
- **モダンで美しいデザイン (Premium UI)**:
  - グラスモフィズム（ガラスのような半透明のエフェクト）を取り入れたダークテーマ。
  - オフラインモード時には、編集エリアの無効化（読み取り専用）やオフラインを示すバナー表示など、直感的で美しいユーザー体験を提供します。
- **かんたんデプロイ**:
  - GitHub Pages へ Flutter Web アプリをワンコマンドでデプロイするためのシェルスクリプト `deploy.sh` を同梱しています。
  - セキュリティ保護のため、OAuth の Client ID などの個人環境設定は gitignore された `lib/config.dart` で管理できるように設計されています。

---

## 使い方・セットアップ手順

### 前提条件
- **Flutter SDK**: 3.12.0 以上を推奨。
- **Google Cloud Console プロジェクト**: Google ログインと Google Drive API を有効化し、OAuth 2.0 クライアント ID を取得する必要があります。

---

### ステップ 1: Google Cloud Console の設定

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセスし、プロジェクトを作成または選択します。
2. **API とサービス > ライブラリ** から `Google Drive API` を検索し、有効化します。
3. **OAuth 同意画面** を設定します：
   - アプリ名、ユーザーサポートメールなどを設定。
   - スコープに `.../auth/drive.file` (Google Drive: アプリが作成したファイルやフォルダの表示、編集、作成、削除) を追加します。
4. **認証情報** から「認証情報を作成」＞「OAuth クライアント ID」を選択します：
   - アプリケーションの種類: `ウェブ アプリケーション`
   - **承認された JavaScript 生成元**:
     - ローカル検証用: `http://localhost:5000` (またはデバッグ時のポート番号)
     - 本番デプロイ用: `https://<あなたのGitHubユーザー名>.github.io`
   - **承認されたリダイレクト URI**: 必要に応じて設定（通常は空欄または JavaScript 生成元と同じ）
5. 生成された **クライアント ID**（例: `xxxxxx.apps.googleusercontent.com`）をコピーします。

---

### ステップ 2: アプリケーションの設定

セキュリティ保護のため、クライアント ID は Git の管理対象から外して管理します。

1. テンプレートファイル [lib/config.dart.example](file:///Users/takano/Antigravity/google-drive-app/lib/config.dart.example) をコピーして、 `lib/config.dart` を作成します。
   ```bash
   cp lib/config.dart.example lib/config.dart
   ```
2. 作成した `lib/config.dart` を開き、ステップ 1 でコピーしたクライアント ID を設定します。
   ```dart
   class AppConfig {
     static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com'; // ここを書き換える
   }
   ```
   > [!NOTE]
   > `lib/config.dart` は `.gitignore` に登録されているため、GitHub 等の公開リポジトリに誤ってプッシュされることはありません。

---

### ステップ 3: ローカルで実行する

1. 依存関係のインストール:
   ```bash
   flutter pub get
   ```
2. Web デバッグ実行（ポートを Google Cloud Console で指定した JavaScript 生成元に合わせることをお勧めします。例: `5000` ポート）:
   ```bash
   flutter run -d chrome --web-port=5000
   ```
   > [!TIP]
   > ポート番号を指定して起動することで、Google ログイン時の `idpiframe_initialization_failed` 等のドメイン不一致エラーを防ぐことができます。

---

### ステップ 4: GitHub Pages へのデプロイ

リポジトリを GitHub にホストしたあと、同梱の `deploy.sh` スクリプトを使って簡単に GitHub Pages にデプロイできます。

1. リモートリポジトリ（`origin`）が設定されていることを確認します：
   ```bash
   git remote -v
   ```
2. デプロイスクリプトを実行します：
   ```bash
   chmod +x deploy.sh # 初回のみ実行権限を付与
   ./deploy.sh
   ```
3. 処理完了後、 `https://<あなたのGitHubユーザー名>.github.io/<リポジトリ名>/` にアクセスするとアプリが公開されます。
   > [!IMPORTANT]
   > 公開URLで Google ログインを行うためには、Google Cloud Console の「承認された JavaScript 生成元」に本番環境のURL（例: `https://<あなたのGitHubユーザー名>.github.io`）が登録されている必要があります。

---

## 開発とトラブルシューティング

### Q. WiFiを切ってリロードしたら最初の画面に戻ってしまうが？
オフライン時は Google ログインが利用できないため、初回画面に戻ります。しかし、画面上に **「Continue Offline」** ボタンが表示されます。このボタンを押すことで、ローカルキャッシュから過去に同期されたドキュメントを読み込んで閲覧することができます。

### Q. Google Drive 内にフォルダーが重複して作られる
本アプリは `drive.file` スコープを使用しています。このスコープの特性上、**「アプリ自身が作成したファイル・フォルダ」**にしかアクセスできません。
そのため、ユーザーが Google Drive の Web 画面等から手動で `"CloudSync Docs"` というフォルダを作成してしまっていると、アプリはそのフォルダを認識できず、新しくアプリ用の `"CloudSync Docs"` フォルダを別個に自動作成します。
フォルダの作成はアプリに任せ、手動でのフォルダ事前作成は行わないようにしてください。
