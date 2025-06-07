# MogumoguMonitoring
子供がちゃんと食べているかを監視するアプリ。その名も「もぐもぐ監視アプリ」

## プロジェクト構成

### mogumogu_monitoring/
人の唇の動きを検知して、食べているかどうかを判定するFlutterアプリです。

**主な機能:**
- リアルタイム顔検出とランドマーク検出
- 唇の動きによる食事判定
- カスタマイズ可能な設定（閾値、判定時間、カメラ選択）
- 統計情報の表示
- 音声アラート機能

**技術スタック:**
- Flutter
- Google ML Kit (顔検出)
- Camera Plugin
- AudioPlayers
- SharedPreferences

### youtube_cast_controller/
（既存のプロジェクト）

## セットアップ

各プロジェクトのREADMEファイルを参照してください：
- [もぐもぐ監視アプリ](./mogumogu_monitoring/README.md)

## 開発環境

- Flutter SDK 3.8.1以上
- Android Studio / Xcode
- 対応プラットフォーム: Android, iOS
