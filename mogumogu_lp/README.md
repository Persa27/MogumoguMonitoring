# もぐもぐウォッチ - ランディングページ

AI育児アプリ「もぐもぐウォッチ」のランディングページです。元のHTMLファイルをReactに変換し、Stagewiseツールバーを統合しています。

## 🚀 特徴

- **React + TypeScript**: モダンなフロントエンド技術スタック
- **TailwindCSS**: ユーティリティファーストのCSSフレームワーク
- **Stagewise統合**: 開発環境でのビジュアル編集ツール
- **レスポンシブデザイン**: モバイルファーストのアプローチ
- **アニメーション**: スムーズなスクロールアニメーション

## 🛠️ 技術スタック

- React 18
- TypeScript
- TailwindCSS
- Stagewise Toolbar
- Google Fonts (Pacifico, Poppins, Noto Sans JP)
- Remix Icons

## 📦 インストール

```bash
# 依存関係のインストール
npm install

# 開発サーバーの起動
npm start

# ビルド
npm run build
```

## 🎨 Stagewise統合

このプロジェクトはStagewise（ビジュアルコーディングツール）と統合されています。

### 開発環境での使用

1. VS Code拡張機能をインストール:
   - [Stagewise VS Code Extension](https://marketplace.visualstudio.com/items?itemName=stagewise.stagewise-vscode-extension)

2. 開発サーバーを起動:
   ```bash
   npm start
   ```

3. ブラウザでアプリケーションを開くと、Stagewiseツールバーが表示されます（開発環境のみ）

### Stagewiseの機能

- **要素選択**: ブラウザ上で直接UI要素を選択
- **コメント機能**: 選択した要素にコメントを追加
- **AI連携**: VS CodeのAIエージェントと連携してコード編集

## 📁 プロジェクト構造

```
src/
├── components/          # Reactコンポーネント
│   ├── Header.tsx
│   ├── HeroSection.tsx
│   ├── PainPointsSection.tsx
│   ├── SolutionSection.tsx
│   ├── FeaturesSection.tsx
│   ├── BenefitBanner.tsx
│   ├── HowItWorksSection.tsx
│   ├── PricingSection.tsx
│   ├── FAQSection.tsx
│   ├── PrivacyBanner.tsx
│   └── Footer.tsx
├── utils/               # ユーティリティ関数
│   └── smoothScroll.ts
├── App.tsx             # メインアプリケーション
├── App.css             # アプリケーションスタイル
└── index.css           # グローバルスタイル
```

## 🎯 主要機能

### セクション

1. **ヒーローセクション**: メインビジュアルとキャッチコピー
2. **課題提起**: ユーザーの悩みを明確化
3. **ソリューション**: 製品の解決方法を3ステップで説明
4. **機能紹介**: 主要機能の詳細説明
5. **お客様の声**: 実際の利用者からの評価
6. **使い方**: アプリの使用方法をステップバイステップで説明
7. **料金プラン**: 無料プランとプレミアムプランの比較
8. **FAQ**: よくある質問と回答
9. **プライバシー**: セキュリティに関する情報
10. **フッター**: 会社情報とリンク

### インタラクティブ機能

- **スムーズスクロール**: アンカーリンクでのスムーズな画面遷移
- **モバイルメニュー**: レスポンシブなハンバーガーメニュー
- **FAQアコーディオン**: 質問をクリックして回答を表示
- **スクロールアニメーション**: 画面に入った要素のフェードイン効果

## 🎨 デザインシステム

### カラーパレット

- **プライマリ**: `#58C694` (緑)
- **セカンダリ**: `#FFB37B` (オレンジ)

### フォント

- **日本語**: Noto Sans JP
- **英語**: Poppins
- **ロゴ**: Pacifico

## 📱 レスポンシブ対応

- **モバイル**: 320px〜
- **タブレット**: 768px〜
- **デスクトップ**: 1024px〜

## 🚀 デプロイ

```bash
# 本番ビルド
npm run build

# ビルドファイルは build/ ディレクトリに生成されます
```

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 🤝 コントリビューション

1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/AmazingFeature`)
3. 変更をコミット (`git commit -m 'Add some AmazingFeature'`)
4. ブランチにプッシュ (`git push origin feature/AmazingFeature`)
5. プルリクエストを作成

## 📞 サポート

質問や問題がある場合は、GitHubのIssuesページでお知らせください。
