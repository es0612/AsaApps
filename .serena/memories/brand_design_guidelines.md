# ブランド・デザインガイドライン

## カラーパレット
- **AsaCoffeeBrown**: #C68C53 (プライマリカラー、ボタン、テキスト)
- **AsaMocha**: #8B5A2B (セカンダリカラー、背景、アクセント)
- **AsaSoftCream**: #E8D5B9 (ハイライト、選択状態)
- **AsaDarkSlate**: #2F3E46 (ニュートラル、背景)
- **AsaMutedSage**: #7A918D (アクセント、微細な要素)

## デザイン原則
- シンプルで温かみのある美学
- ブランドカラーの一貫した使用
- 角丸（標準10px）
- 奥行き感のためのシャドウ効果
- 家族向けで生産性重視のテーマ

## 共有UIコンポーネント

### AsaButton
- フォント: .title2, medium
- 配色: AsaCoffeeBrown (デフォルト)
- 角丸: 10px
- シャドウ: 2px
- アニメーション: 0.2秒のeaseInOut

```swift
AsaButton(title: "+1", action: { count += 1 }, color: Color("AsaCoffeeBrown"))
```

### AsaCard
- 背景: 白色半透明（opacity 0.8）
- 角丸: 15px
- シャドウ: 2px
- パディング: 標準padding

```swift
AsaCard {
    Text("サンプルテキスト")
        .font(.body.weight(.medium))
        .foregroundColor(.asaCoffeeBrown)
}
```

## 色の使用方法
SwiftUIでのブランドカラー使用：
```swift
.foregroundColor(Color("AsaCoffeeBrown"))
.background(Color("AsaDarkSlate"))
```

## ロゴガイドライン
- ファイル: Designs/AsaPapaLabLogo.png
- メインカラー: AsaCoffeeBrown (#C68C53)
- 推奨背景: AsaDarkSlate または AsaSoftCream
- 最小サイズ: 100x100px