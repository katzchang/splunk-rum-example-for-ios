# Splunk iOS RUM デモアプリ構築プラン

## 概要

Splunk iOS RUM エージェントを組み込んだデモ用 iOS アプリケーションを構築する。

## 要件

- **Splunk O11y アカウント**: あり（realm, token は後で設定）
- **Session Replay**: 有効化する
- **アプリ機能**:
  - WebView 操作（複数）
  - カメラ機能
  - Face ID（顔認証）
- **複雑さ**: シンプルで良い

---

## Phase 1: 前提条件の確認・準備

### 1.1 開発環境の確認
- [ ] macOS + Xcode（最新版推奨）
- [ ] iOS 15 以上対応のシミュレータまたは実機
- [ ] Face ID 対応デバイス（実機テスト用）またはシミュレータの Face ID 設定

### 1.2 Splunk Observability Cloud の情報準備
- [ ] RUM Access Token の取得
- [ ] Realm の確認（例: us0, us1, eu0 など）
- [ ] デプロイ環境名の決定（例: demo）

---

## Phase 2: iOS サンプルアプリの設計

### 2.1 アプリ構成（画面設計）

```
ホーム画面
├── WebView デモ画面
│   ├── 外部サイト表示（例: サンプル Web ページ）
│   ├── フォーム入力のある WebView
│   └── JavaScript 連携デモ
├── カメラ画面
│   └── 写真撮影機能
├── 認証画面
│   └── Face ID 認証デモ
└── 設定/情報画面
    └── クラッシュ発生ボタン（デモ用）
```

### 2.2 RUM デモ対象機能

| 機能 | RUM で計測される内容 |
|------|---------------------|
| 画面遷移 | Navigation Tracking |
| WebView 操作 | Browser RUM 連携（session.id 共有） |
| API 通信 | Network Monitoring |
| カメラ起動 | カスタムイベント |
| Face ID | カスタムイベント + 成功/失敗追跡 |
| 意図的クラッシュ | Crash Reporting |
| UI 操作 | Interaction Tracking（タップ追跡） |
| Session Replay | ユーザー操作の録画 |

### 2.3 必要な権限（Info.plist）

- `NSCameraUsageDescription` - カメラアクセス
- `NSFaceIDUsageDescription` - Face ID 使用

---

## Phase 3: プロジェクト作成

### 3.1 Xcode プロジェクトの新規作成
- [ ] iOS App テンプレート選択
- [ ] Interface: SwiftUI
- [ ] Language: Swift
- [ ] Bundle Identifier 設定
- [ ] Minimum Deployments: iOS 15.0

### 3.2 Swift Package Manager で Splunk Agent 追加
- [ ] File > Add Package Dependencies...
- [ ] URL: `https://github.com/signalfx/splunk-otel-ios`
- [ ] `SplunkAgent` パッケージを選択して追加

---

## Phase 4: RUM エージェントの実装

### 4.1 エージェントの初期化

```swift
import SplunkAgent

// App.swift または AppDelegate で初期化
let endpointConfiguration = EndpointConfiguration(
    realm: "<YOUR_REALM>",           // 後で設定
    rumAccessToken: "<YOUR_TOKEN>"   // 後で設定
)

let agentConfiguration = AgentConfiguration(
    endpoint: endpointConfiguration,
    appName: "SplunkRUMDemo",
    deploymentEnvironment: "demo"
)

var agent: SplunkRum?

do {
    agent = try SplunkRum.install(with: agentConfiguration)
} catch {
    print("Unable to start the Splunk agent: \(error)")
}
```

### 4.2 モジュール有効化

```swift
// Navigation Tracking 自動追跡
agent?.navigation.preferences.enableAutomatedTracking = true

// Session Replay 開始
agent?.sessionReplay.start()
```

### 4.3 WebView と Browser RUM の連携

- WKWebView で session.id を共有して、ネイティブ RUM とブラウザ RUM を統合表示

---

## Phase 5: デモ用 UI の実装

### 5.1 ホーム画面
- [ ] 各機能へのナビゲーションリンク
- [ ] アプリ説明テキスト

### 5.2 WebView デモ画面
- [ ] WKWebView の実装
- [ ] 複数の URL を切り替え可能に
- [ ] Browser RUM 連携設定

### 5.3 カメラ画面
- [ ] UIImagePickerController または AVCaptureSession
- [ ] 撮影ボタン
- [ ] カスタムスパンでカメラ操作を記録

### 5.4 Face ID 認証画面
- [ ] LocalAuthentication フレームワーク使用
- [ ] 認証成功/失敗の表示
- [ ] カスタムスパンで認証イベントを記録

### 5.5 設定/デバッグ画面
- [ ] クラッシュ発生ボタン（Crash Reporting デモ）
- [ ] 重い処理実行ボタン（Frozen Frame デモ）

---

## Phase 6: テスト・検証

### 6.1 ローカルでの動作確認
- [ ] シミュレータで基本動作確認
- [ ] 実機でカメラ・Face ID 動作確認

### 6.2 Splunk Observability Cloud での確認
- [ ] RUM ダッシュボードでデータ受信確認
- [ ] セッション一覧の表示確認
- [ ] 画面遷移の追跡確認
- [ ] ネットワークリクエストの表示確認
- [ ] Session Replay の再生確認
- [ ] クラッシュレポートの確認

---

## Phase 7: 仕上げ

### 7.1 dSYM アップロード設定
- [ ] クラッシュレポートのシンボル化用スクリプト設定

### 7.2 ドキュメント整備
- [ ] README.md 作成
- [ ] セットアップ手順
- [ ] デモシナリオの作成

---

## 参考リンク

- [Splunk RUM iOS Agent v2.0.0 以上](https://help.splunk.com/en/splunk-observability-cloud/manage-data/instrument-front-end-applications/instrument-mobile-and-web-applications-for-splunk-rum/instrument-ios-applications-for-splunk-rum/splunk-rum-ios-agent-version-2.0.0-and-above)
- [GitHub - splunk-otel-ios](https://github.com/signalfx/splunk-otel-ios)
- [Install the Splunk RUM iOS agent](https://help.splunk.com/en/splunk-observability-cloud/manage-data/instrument-front-end-applications/instrument-mobile-and-web-applications-for-splunk-rum/instrument-ios-applications-for-splunk-rum/splunk-rum-ios-agent-version-2.0.0-and-above/install-the-splunk-rum-ios-agent)

---

## メモ

- Realm: (後で記入)
- RUM Access Token: (後で記入)
