# Splunk RUM Demo for iOS

Splunk Real User Monitoring (RUM) の機能をデモンストレーションするためのiOSサンプルアプリです。

## 機能

- WebView デモ
- カメラ
- Face ID 認証
- カスタムイベント送信
- ネットワークエラーシミュレーション（404, 500, タイムアウト等）
- アプリケーションエラー / クラッシュ
- セッションリプレイ
- サンプリング状態表示

## 必要環境

- Xcode 15.0+
- iOS 16.0+
- Splunk Observability Cloud アカウント（RUM アクセストークン）

## セットアップ

1. リポジトリをクローン

```bash
git clone https://github.com/katzchang/splunk-rum-example-for-ios.git
cd splunk-rum-example-for-ios/SplunkRUMDemo
```

2. 設定ファイルを作成

```bash
cp Secrets.xcconfig.template Secrets.xcconfig
```

3. `Secrets.xcconfig` を編集して Splunk RUM の認証情報を設定

```
SPLUNK_RUM_REALM = your-realm-here
SPLUNK_RUM_ACCESS_TOKEN = your-access-token-here
SPLUNK_RUM_ENVIRONMENT = (optional, defaults to "test")
```

4. Xcode でプロジェクトを開く

```bash
open SplunkRUMDemo.xcodeproj
```

5. シミュレーターまたは実機でビルド・実行

## ライセンス

MIT
