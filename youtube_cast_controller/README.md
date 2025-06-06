# YouTube Cast Controller

YouTubeアプリがTVにキャストしている状態で、その動画を制御するFlutterアプリです。

## 機能

- **再生/一時停止制御**: キャストしているYouTube動画の再生と一時停止
- **シーク機能**: 動画の任意の位置への移動
- **早送り/巻き戻し**: 10秒単位での早送りと巻き戻し
- **リアルタイム状態表示**: 動画のタイトル、再生位置、再生状態の表示
- **Cast接続状態監視**: Cast接続の自動検出と状態表示

## 前提条件

1. **Android端末でYouTubeアプリが起動している**
2. **YouTubeアプリからTVにキャストしている状態**
3. **同じWi-Fiネットワークに接続している**

## セットアップ

### 1. 依存関係のインストール

```bash
cd youtube_cast_controller
flutter pub get
```

### 2. Android設定

アプリは以下のAndroid権限を使用します：

- `INTERNET`: Cast通信用
- `ACCESS_NETWORK_STATE`: ネットワーク状態確認用
- `ACCESS_WIFI_STATE`: Wi-Fi状態確認用
- `CHANGE_WIFI_MULTICAST_STATE`: Cast検出用

### 3. ビルドと実行

```bash
# デバッグビルド
flutter run

# リリースビルド
flutter build apk --release
```

## 使用方法

### 基本的な使い方

1. **YouTubeアプリでキャスト開始**
   - YouTubeアプリを開く
   - 動画を選択
   - キャストボタンをタップしてTVに接続

2. **Cast Controllerアプリを起動**
   - アプリを開くと自動的にCast状態を検出
   - 接続状態が「Cast接続中」と表示される

3. **動画制御**
   - 中央の再生/一時停止ボタンで制御
   - 左右のボタンで10秒巻き戻し/早送り
   - スライダーで任意の位置にシーク

### UI説明

#### 接続状態カード
- **緑のキャストアイコン**: Cast接続中
- **グレーのキャストアイコン**: Cast未接続

#### メディア情報カード
- 動画タイトルとチャンネル名を表示
- Cast接続時のみ表示

#### 制御ボタン
- **⏪ 10秒戻る**: 現在位置から10秒巻き戻し
- **▶️/⏸️ 再生/一時停止**: メイン制御ボタン
- **⏩ 10秒進む**: 現在位置から10秒早送り

#### プログレスバー
- 現在の再生位置と総時間を表示
- スライダーをドラッグしてシーク可能

## トラブルシューティング

### Cast接続が検出されない場合

1. **同じWi-Fiネットワークに接続しているか確認**
2. **YouTubeアプリでキャストが開始されているか確認**
3. **「状態を更新」ボタンをタップ**
4. **アプリを再起動**

### 制御が効かない場合

1. **Cast接続状態を確認**
2. **YouTubeアプリが前面に表示されていないか確認**
3. **TV側でYouTube動画が再生されているか確認**

### エラーメッセージ

- **"Castデバイスに接続されていません"**: YouTubeアプリでキャストを開始してください
- **"再生制御に失敗しました"**: Cast接続を確認し、アプリを再起動してください

## 技術仕様

### 使用技術
- **Flutter**: UI フレームワーク
- **Google Cast SDK**: Cast制御
- **Kotlin**: Android ネイティブコード
- **Method Channel**: Flutter-Android間通信

### 対応プラットフォーム
- Android 5.0 (API level 21) 以上

### Cast対応デバイス
- Chromecast
- Android TV
- Google Nest Hub
- Cast対応スマートTV

## 開発者向け情報

### プロジェクト構造

```
youtube_cast_controller/
├── lib/
│   ├── main.dart              # メインアプリケーション
│   └── cast_controller.dart   # Cast制御ロジック
├── android/
│   └── app/src/main/kotlin/
│       └── com/example/youtube_cast_controller/
│           ├── MainActivity.kt           # メインアクティビティ
│           └── CastOptionsProvider.kt    # Cast設定
└── README.md
```

### Method Channel API

#### `youtube_cast_controller`
- `initialize()`: Cast制御初期化
- `isConnected()`: Cast接続状態確認
- `play()`: 再生
- `pause()`: 一時停止
- `seekTo(position)`: シーク
- `getCurrentMediaInfo()`: メディア情報取得

#### `youtube_cast_bridge`
- `sendPlayPauseCommand()`: システムレベルの再生/一時停止
- `getCastVideoInfo()`: Cast動画情報取得

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 注意事項

- このアプリはYouTubeの公式アプリではありません
- Cast機能はGoogle Cast SDKを使用しています
- YouTube Premium機能には対応していません
- 一部の動画では制御が制限される場合があります
