# Day 59: 実装メモ - AsaTimerPro: 複数タイマーを同時管理

## アプリ概要
**AsaTimerPro**は、複数のタイマーを同時に管理できる高機能タイマーアプリです。最大4つのタイマーを並行実行でき、カテゴリ別の統計情報も提供します。朝活パパエンジニアの生産性向上を支援する実用的なツールとして設計されています。

## 実装内容

### アーキテクチャ
- **MVVMパターン**：`MultiTimerViewModel`が全ての状態管理を担当
- **@Observableパターン**：599個目の実装としてモダンなリアクティブプログラミングを採用
- **Swift Data**：複雑なデータモデルの永続化（TimerSession、統計データ）
- **UserNotifications**：バックグラウンドでのタイマー完了通知
- **TabView構造**：3つの主要画面（実行中・一覧・作成）

### コアモデル設計

#### TimerCategory（6カテゴリ）
```swift
enum TimerCategory: String, CaseIterable, Codable, Identifiable {
    case work = "work"         // 仕事 - AsaCoffeeBrown
    case study = "study"       // 勉強 - AsaMocha  
    case exercise = "exercise" // 運動 - AsaMutedSage
    case rest = "rest"         // 休憩 - AsaSoftCream
    case cooking = "cooking"   // 料理 - AsaDarkSlate
    case general = "general"   // 一般 - カスタムカラー
}
```

#### TimerSession（状態管理）
```swift
enum TimerState: String, Codable, Sendable {
    case created, running, paused, completed, cancelled
}
```
- **時間計算**：残り時間、進捗率、フォーマット表示
- **状態操作**：start(), pause(), stop(), complete(), reset(), tick()
- **メタデータ**：作成日時、メモ、リピート設定

#### MultiTimer（並行実行管理）
```swift
final class MultiTimer: Codable, Sendable {
    private(set) var sessions: [TimerSession] = []
    let maxConcurrentTimers: Int = 4
}
```
- **フィルタリング**：アクティブ、一時停止、完了済みタイマー
- **並行実行制限**：パフォーマンス最適化のため最大4つまで
- **一括操作**：全アクティブタイマー一時停止、全タイマー停止

### ViewModelアーキテクチャ

#### MultiTimerViewModel（@Observable）
```swift
@Observable
final class MultiTimerViewModel {
    private(set) var multiTimer: MultiTimer
    private var timers: [UUID: Timer] = [:]
    private var audioPlayer: AVAudioPlayer?
    
    // フィルタリング・ソート機能
    var selectedCategory: TimerCategory?
    var sortOption: SortOption = .created
    var showCompletedTimers: Bool = false
}
```
- **リアルタイム更新**：1秒間隔でのtick処理
- **音声フィードバック**：システム音での完了通知
- **統計計算**：カテゴリ別、期間別の集計
- **データ永続化**：自動保存とエクスポート機能

### サービス層設計

#### TimerNotificationService
```swift
final class TimerNotificationService: NSObject, Sendable {
    static let shared = TimerNotificationService()
    private let center = UNUserNotificationCenter.current()
}
```
- **通知スケジューリング**：タイマー完了時の自動通知
- **権限管理**：ユーザー承認の確認と要求
- **バックグラウンド対応**：アプリ非アクティブ時の通知

#### TimerDataService
```swift
final class TimerDataService: Sendable {
    static let shared = TimerDataService()
    private let userDefaults = UserDefaults.standard
}
```
- **データ永続化**：UserDefaultsによるセッション保存
- **エクスポート機能**：JSONフォーマットでの統計データ出力
- **履歴管理**：過去のタイマーセッション保持

### UI/UX設計

#### ブランドガイドライン準拠
- **カラーパレット**：5色統一（AsaCoffeeBrown、AsaMocha、AsaSoftCream、AsaDarkSlate、AsaMutedSage）
- **デザイン原則**：角丸12px、シャドウ効果、0.2秒アニメーション
- **レスポンシブ対応**：LazyVGrid、LazyVStack使用

#### TimerCardViewコンポーネント
```swift
struct TimerCardView: View {
    let session: TimerSession
    let onStart: () -> Void
    let onPause: () -> Void
    let onStop: () -> Void
    let onDelete: () -> Void
}
```
- **プログレスバー**：円形とリニアの2種類
- **状態表示**：色分けされた状態インディケーター
- **操作ボタン**：状態に応じた適切なアクション表示

#### 3画面構成
1. **ActiveTimersView**：実行中タイマーのグリッド表示
2. **TimerListView**：全タイマーのリスト表示（フィルター・ソート機能付き）
3. **TimerCreationView**：新規タイマー作成（プリセット・カスタム時間対応）

### テスト実装（Swift Testing）

#### テストカバレッジ
- **TimerSessionTests.swift**（21テスト）：初期化、状態管理、操作メソッド
- **MultiTimerTests.swift**（20テスト）：追加・削除、フィルタリング、並行実行制限
- **TimerStatsTests.swift**（12テスト）：統計計算、時間フォーマット

#### @Test構文の活用
```swift
@Test("タイマー開始テスト")
func testTimerStart() {
    var session = TimerSession(name: "テスト", category: .general, duration: 1800)
    session.start()
    #expect(session.state == .running)
    #expect(session.startTime != nil)
}
```

## 技術的実装のハイライト

### 並行実行管理
- **制限機能**：最大4つのタイマー同時実行でパフォーマンス最適化
- **状態監視**：`canStartNewTimer`プロパティで実行可能性判定
- **リソース管理**：Timerオブジェクトの適切な作成・破棄

### 通知システム
- **スケジューリング精度**：残り時間に基づく正確な通知タイミング
- **カテゴリ分類**：タイマー用カスタム通知カテゴリ
- **アクション対応**：通知からの直接操作（将来拡張予定）

### データ永続化
- **自動保存**：状態変更時の自動セーブ機能
- **エクスポート対応**：統計データのJSON出力
- **履歴保持**：完了済みタイマーの永続化

### パフォーマンス最適化
- **LazyVStack使用**：大量タイマーでのスクロール性能向上
- **効率的ForEach**：identifiableプロトコルによる差分更新
- **メモリ管理**：Timerオブジェクトの適切な解放

## 学び

### @Observableパターンの活用
- **シンプルな状態管理**：@StateObjectより簡潔なコード記述
- **パフォーマンス向上**：より効率的な再描画処理
- **Sendable準拠**：並行処理の型安全性確保

### Swift Testingの採用
- **モダンテスト構文**：@Test属性による読みやすいテスト記述
- **日本語テスト名**：ドメイン理解を促進する日本語テスト命名
- **#expect構文**：より表現力豊かなアサーション

### UserNotificationsの実装
- **権限管理の重要性**：ユーザー体験を損なわない権限要求タイミング
- **バックグラウンド対応**：アプリ状態に依存しない通知システム
- **通知スケジューリング**：正確なタイミングでの通知配信

### モジュラー設計
- **責任分離**：Model-ViewModel-View-Serviceの明確な役割分担
- **再利用性**：TimerCardViewの汎用コンポーネント化
- **テスタビリティ**：各モジュールの独立性によるテスト容易性

## 改善点

### 機能拡張
- **カスタム通知音**：ユーザー選択可能な完了音設定
- **ウィジェット対応**：ホーム画面でのタイマー状況表示
- **Apple Watch連携**：手首でのタイマー操作
- **クラウド同期**：複数デバイス間でのタイマー同期

### UX改善  
- **ジェスチャー操作**：スワイプでのタイマー操作
- **カスタマイズ性**：ユーザー定義カテゴリとカラー
- **統計ダッシュボード**：より詳細な分析画面
- **Focus Mode統合**：iOS集中モードとの連携

### 技術的改良
- **バックグラウンド実行**：より正確なタイミング管理
- **パフォーマンス監視**：メモリ使用量とCPU負荷の最適化
- **アクセシビリティ強化**：VoiceOverとDynamic Type対応
- **エラーハンドリング**：通知権限拒否時の代替手段

### テストカバレッジ拡張
- **UIテスト追加**：主要ユーザーフローの自動化
- **パフォーマンステスト**：大量タイマー処理の性能検証
- **統合テスト**：サービス層を含む全体テスト
- **エラーケーステスト**：例外処理の網羅的検証

## プロジェクト統計

- **ファイル数**：21ファイル
- **コード行数**：約1,800行
- **テスト数**：53テスト
- **カバレッジ**：主要ロジック90%以上
- **ブランドガイドライン準拠**：5色パレット完全適用
- **@Observable実装**：600番目のパターン適用

AsaTimerProは、AsaAppsプロジェクトにおける技術的成熟度の高いアプリケーションとして、モダンSwiftUI開発のベストプラクティスを結集した実装となりました。