# Day 74: AsaECommerce 実装ノート

## 概要

**AsaECommerce**は模擬ECサイトアプリです。商品一覧表示、カート機能、決済フロー、注文履歴など、ECサイトの基本的な機能を実装しています。

## 主要機能

### 1. 商品一覧（ProductListView）
- LazyVGridによる2列グリッド表示
- カテゴリフィルター機能
- キーワード検索（searchable）
- ソート機能（新着順、価格順、評価順）

### 2. 商品詳細（ProductDetailView）
- 商品画像、説明、価格、評価表示
- セール価格・割引率表示
- 在庫状況確認
- 数量選択とカート追加

### 3. カート機能（CartView）
- アイテム一覧表示
- 数量変更（QuantitySelector）
- スワイプ削除
- 小計・送料・合計金額計算

### 4. 決済フロー（CheckoutView）
- ステップ形式のUI（配送先→支払い→確認）
- 配送先入力フォーム
- 支払い方法選択（クレジット/銀行振込/代引き）
- 注文確認・確定

### 5. 注文履歴（OrderHistoryView）
- 注文一覧表示
- 注文ステータス表示
- 注文詳細画面

## 技術スタック

### アーキテクチャ
- **MVVM パターン**: Model-View-ViewModel分離
- **@Observable**: リアクティブ状態管理（ProductViewModel, CartViewModel等）
- **@MainActor**: UIスレッド安全性保証

### データ永続化
- **JSONファイル**: 商品マスタデータ（バンドル同梱）
- **UserDefaults**: カートデータ永続化
- **SwiftData**: 注文履歴保存（@Modelマクロ）

### UI
- **AsaUIKit**: 共有コンポーネント活用（AsaButton, AsaCard, AsaColors）
- **LazyVGrid**: 商品グリッド表示
- **TabView**: 3タブ構成（商品/カート/履歴）

## ディレクトリ構成

```
AsaECommerce/
├── AsaECommerce/
│   ├── AsaECommerceApp.swift       # エントリーポイント
│   ├── ContentView.swift           # TabView
│   ├── Models/
│   │   ├── Product.swift           # 商品モデル
│   │   ├── Category.swift          # カテゴリ
│   │   ├── CartItem.swift          # カートアイテム
│   │   ├── Order.swift             # 注文（SwiftData）
│   │   └── ShippingAddress.swift   # 配送先
│   ├── ViewModels/
│   │   ├── ProductViewModel.swift
│   │   ├── CartViewModel.swift
│   │   ├── CheckoutViewModel.swift
│   │   └── OrderViewModel.swift
│   ├── Views/
│   │   ├── Product/                # 商品関連
│   │   ├── Cart/                   # カート関連
│   │   ├── Checkout/               # 決済関連
│   │   └── Order/                  # 注文履歴関連
│   ├── Components/
│   │   ├── QuantitySelector.swift
│   │   ├── CategoryChip.swift
│   │   ├── PriceLabel.swift
│   │   └── RatingView.swift
│   └── Resources/
│       └── products.json           # 模擬商品データ
├── AsaECommerceTests/
│   ├── ProductTests.swift
│   └── CartItemTests.swift
└── project.yml
```

## データモデル設計

### Product（商品）
```swift
struct Product: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let originalPrice: Double?      // セール前価格
    let imageURL: String            // SF Symbol名
    let categoryId: UUID
    let stockQuantity: Int
    let rating: Double
    let reviewCount: Int
    let tags: [String]
    let createdAt: Date

    var isOnSale: Bool              // セール中判定
    var discountPercentage: Int?    // 割引率
    var isInStock: Bool             // 在庫有無
    var formattedPrice: String      // 表示用価格
}
```

### Order（注文）- SwiftData
```swift
@Model
final class Order {
    @Attribute(.unique) var id: UUID
    var orderNumber: String         // ASA-20250114...-XXXX
    var itemsData: Data             // JSON化した注文アイテム
    var subtotal: Double
    var shippingFee: Double         // 固定500円
    var totalAmount: Double
    var statusRawValue: String
    var shippingAddressData: Data
    var paymentMethodRawValue: String
    var createdAt: Date
    var updatedAt: Date
}
```

## 実装のポイント

### 1. FlowLayout（タグ表示）
商品詳細のタグ表示にカスタムLayoutを実装。横幅に応じて自動的に折り返す。

```swift
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ())
}
```

### 2. トースト通知
カート追加時にトースト通知を表示。CartViewModelの`toastMessage`で管理し、2秒後に自動消去。

### 3. 決済ステップ管理
CheckoutViewModelでステップ状態を管理。各ステップのバリデーションを実施。

### 4. 注文番号生成
日時ベース＋ランダム4桁で一意の注文番号を生成。
```
ASA-20250114123456-1234
```

## ブランドガイドライン適用

| 要素 | カラー |
|------|--------|
| プライマリボタン | AsaColors.coffeeBrown |
| 価格表示 | AsaColors.coffeeBrown |
| 割引前価格 | AsaColors.mutedSage + 取り消し線 |
| カード背景 | AsaColors.cardBackground |
| テキスト | AsaColors.darkSlate |

## 今後の拡張可能性

- [ ] 商品画像のAsyncImage対応
- [ ] お気に入り機能
- [ ] レビュー投稿機能
- [ ] クーポン適用機能
- [ ] 配送先保存機能

## 学習ポイント

1. **SwiftDataとUserDefaultsの使い分け**: 複雑なリレーションにはSwiftData、シンプルなデータにはUserDefaults
2. **ステップ形式UIの実装**: enum＋ViewBuilderで柔軟なステップ管理
3. **カスタムLayoutの作成**: Layout protocolを使った自由度の高いレイアウト
4. **@Observable活用**: iOS 17以降の新しい状態管理パターン
