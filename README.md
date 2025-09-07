# もぐもぐウォッチ - Landing Page

HTMLファイルから変換されたReactプロジェクトです。AI育児アプリ「もぐもぐウォッチ」のランディングページを提供します。

## 🎯 プロジェクト概要

「もぐもぐウォッチ」は、AIが子どもの咀嚼を見守り、食事中にテレビを自動制御するスマート育児アプリのランディングページです。

## 🚀 開始方法

### 前提条件
- Node.js (v16以上)
- npm または yarn

### インストール
```bash
cd mogumogu_lp
npm install
```

### 開発サーバーの起動
```bash
npm start
```

ブラウザで `http://localhost:3000` を開いてください。

### ビルド
```bash
npm run build
```

## 🏗️ プロジェクト構造

```
mogumogu_lp/
├── src/
│   ├── components/          # Reactコンポーネント
│   │   ├── Header.tsx       # ヘッダーナビゲーション
│   │   ├── HeroSection.tsx  # メインヒーローセクション
│   │   ├── PainPointsSection.tsx  # 課題提示セクション
│   │   ├── SolutionSection.tsx    # 解決策セクション
│   │   ├── FeaturesSection.tsx    # 機能紹介セクション
│   │   ├── BenefitBanner.tsx      # 顧客の声セクション
│   │   ├── HowItWorksSection.tsx  # 使い方セクション
│   │   ├── PricingSection.tsx     # 料金プランセクション
│   │   ├── FAQSection.tsx         # よくある質問セクション
│   │   ├── PrivacyBanner.tsx      # プライバシー保護バナー
│   │   └── Footer.tsx             # フッター
│   ├── utils/
│   │   └── smoothScroll.ts        # スムーススクロール機能
│   ├── App.tsx                    # メインアプリコンポーネント
│   ├── App.css                    # カスタムスタイル
│   └── index.css                  # グローバルスタイル
├── tailwind.config.js             # TailwindCSS設定
├── postcss.config.js              # PostCSS設定
└── package.json                   # 依存関係とスクリプト
```

## 🎨 技術スタック

- **React 19** - UIライブラリ
- **TypeScript** - 型安全性
- **TailwindCSS** - スタイリング
- **Headless UI** - アクセシブルなUIコンポーネント
- **Heroicons** - アイコンライブラリ
- **Remix Icons** - 追加アイコンセット

## 🎯 主な機能

### レスポンシブデザイン
- モバイルファーストアプローチ
- タブレット・デスクトップ対応
- 流動的なレイアウト

### インタラクティブ要素
- スムーススクロールナビゲーション
- モバイルメニュー
- アコーディオン式FAQ
- スクロール連動アニメーション

### アクセシビリティ
- セマンティックHTML
- キーボードナビゲーション対応
- スクリーンリーダー対応
- 適切なコントラスト比

## 🎨 デザインシステム

### カラーパレット
- **Primary**: #58C694 (緑)
- **Secondary**: #FFB37B (オレンジ)
- **グレースケール**: TailwindCSSデフォルト

### フォント
- **日本語**: Noto Sans JP
- **英語**: Poppins
- **ブランド**: Pacifico

### アイコン
- Remix Icons (メインアイコン)
- Heroicons (UIアイコン)

## 📱 セクション構成

1. **Header** - ナビゲーションとCTA
2. **Hero** - メインメッセージとCTA
3. **Pain Points** - 課題の提示
4. **Solution** - 解決策の説明
5. **Features** - 主要機能の紹介
6. **Benefit Banner** - 顧客の声
7. **How It Works** - 使い方の説明
8. **Pricing** - 料金プラン
9. **FAQ** - よくある質問
10. **Privacy Banner** - プライバシー保護
11. **Footer** - 会社情報とリンク

## 🔧 カスタマイズ

### 色の変更
`tailwind.config.js`でカラーパレットを変更できます：

```javascript
colors: {
  primary: '#58C694',    // メインカラー
  secondary: '#FFB37B',  // アクセントカラー
}
```

### コンテンツの編集
各コンポーネントファイルでテキストや画像URLを直接編集できます。

### スタイルの調整
- `src/App.css` - カスタムスタイル
- `src/index.css` - グローバルスタイル
- TailwindCSSクラスで直接スタイリング

## 🚀 デプロイ

### Vercel
```bash
npm run build
# Vercelにデプロイ
```

### Netlify
```bash
npm run build
# build/フォルダをNetlifyにアップロード
```

### その他のホスティング
`npm run build`で生成される`build/`フォルダを任意の静的ホスティングサービスにアップロードしてください。

## 📝 開発メモ

### 完了した作業
- ✅ HTMLからReactコンポーネントへの変換
- ✅ TypeScript対応
- ✅ TailwindCSS設定
- ✅ レスポンシブデザイン実装
- ✅ アニメーション実装
- ✅ アクセシビリティ対応
- ✅ モバイルメニュー実装
- ✅ FAQ アコーディオン実装
- ✅ スムーススクロール実装

### 今後の拡張可能性
- [ ] Stagewise統合（ビジュアル編集）
- [ ] 多言語対応
- [ ] CMS統合
- [ ] A/Bテスト機能
- [ ] アナリティクス統合
- [ ] SEO最適化

## 🤝 貢献

プロジェクトへの貢献を歓迎します。プルリクエストを送信する前に、以下を確認してください：

1. コードがTypeScriptの型チェックを通過する
2. ESLintエラーがない
3. レスポンシブデザインが正常に動作する
4. アクセシビリティ要件を満たしている

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

---

**もぐもぐウォッチ** - AI技術で食事習慣を改善し、家族の時間をより豊かにします。
