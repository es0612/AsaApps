# AsaStudyPlanner 未実装機能の完成計画

## Context

AsaStudyPlannerはAI学習最適化エンジンとSM-2間隔反復学習を統合した学習計画アプリ。調査の結果、以下の2種類の問題が判明した：

1. **未実装ボタン（4箇所）** - DashboardViewとStudyItemDetailViewの「学習開始」「復習」ボタンが空のクロージャ（`// TODO`）
2. **セッション完了時のサービス統合欠落** - SessionView含む全てのセッション完了時にSM-2復習スケジュール更新、LearningAnalytics記録、StudyPlan完了状態更新が行われていない

## 変更ファイル（3ファイルのみ）

1. `Apps/AsaStudyPlanner/AsaStudyPlanner/Views/Dashboard/DashboardView.swift`
2. `Apps/AsaStudyPlanner/AsaStudyPlanner/Views/StudyItems/StudyItemDetailView.swift`
3. `Apps/AsaStudyPlanner/AsaStudyPlanner/Views/Session/SessionView.swift`

既存の `ActiveSessionView`、`SessionCompleteView`、`RatingPicker` は変更不要（そのまま再利用）。

---

## Step 1: DashboardView.swift — クイックアクションボタン実装

### 1a. @State / @Query 追加

```swift
// 既存の @State private var showingAddItem = false の後に追加
@State private var showingActiveSession = false
@State private var sessionTargetItem: StudyItem?
@State private var sessionPlannedMinutes: Int = 25

// @Query 追加（セッション完了統合用）
@Query(sort: \StudyPlan.date, order: .reverse) private var plans: [StudyPlan]
```

Computed property追加:
```swift
private var todayPlan: StudyPlan? {
    plans.first { Calendar.current.isDateInToday($0.date) }
}
```

### 1b. QuickActionsCard にコールバック追加

`QuickActionsCard`のインターフェースを拡張し、2つのクロージャを受け取れるようにする：

```swift
struct QuickActionsCard: View {
    @Binding var showingAddItem: Bool
    let onStartStudy: () -> Void    // 追加
    let onStartReview: () -> Void   // 追加
    // ...
}
```

「学習開始」「復習」ボタンで各クロージャを呼び出す。

### 1c. DashboardView body で呼び出し変更

```swift
QuickActionsCard(
    showingAddItem: $showingAddItem,
    onStartStudy: {
        if let item = topPriorityItems.first {
            sessionTargetItem = item
            sessionPlannedMinutes = item.category.recommendedSessionMinutes
            showingActiveSession = true
        }
    },
    onStartReview: {
        if let item = itemsNeedingReview.first {
            sessionTargetItem = item
            sessionPlannedMinutes = item.category.recommendedSessionMinutes
            showingActiveSession = true
        }
    }
)
```

### 1d. fullScreenCover 追加（`.sheet` の後）

```swift
.fullScreenCover(isPresented: $showingActiveSession) {
    if let item = sessionTargetItem {
        ActiveSessionView(
            studyItem: item,
            plannedMinutes: sessionPlannedMinutes,
            onComplete: { session in
                handleSessionComplete(session: session, item: item)
                showingActiveSession = false
            }
        )
    }
}
```

### 1e. handleSessionComplete メソッド追加

```swift
private func handleSessionComplete(session: StudySession, item: StudyItem) {
    let engine = SpacedRepetitionEngine()
    engine.updateItemAfterSession(item: item, session: session)

    if let analytics = todayAnalytics {
        analytics.recordSession(session, category: item.category)
    } else {
        let newAnalytics = LearningAnalytics(date: Date())
        modelContext.insert(newAnalytics)
        newAnalytics.recordSession(session, category: item.category)
    }

    todayPlan?.markItemCompleted(item.id, minutes: session.actualMinutes, isMorning: session.isMorningSession)
    try? modelContext.save()
}
```

---

## Step 2: StudyItemDetailView.swift — 学習/復習開始ボタン実装

### 2a. @State / @Query 追加

```swift
@State private var showingActiveSession = false

@Query(sort: \LearningAnalytics.date, order: .reverse) private var analytics: [LearningAnalytics]
@Query(sort: \StudyPlan.date, order: .reverse) private var plans: [StudyPlan]
```

Computed property追加:
```swift
private var todayAnalytics: LearningAnalytics? {
    analytics.first { Calendar.current.isDateInToday($0.date) }
}
private var todayPlan: StudyPlan? {
    plans.first { Calendar.current.isDateInToday($0.date) }
}
```

### 2b. TODO ボタン実装（行127-141）

```swift
// 「学習を開始」ボタン
Button {
    showingActiveSession = true
} label: {
    Label("学習を開始", systemImage: "play.fill")
}

// 「復習を開始」ボタン
if item.needsReview {
    Button {
        showingActiveSession = true
    } label: {
        Label("復習を開始", systemImage: "arrow.clockwise")
    }
}
```

### 2c. fullScreenCover 追加（`.alert` の後）

```swift
.fullScreenCover(isPresented: $showingActiveSession) {
    ActiveSessionView(
        studyItem: item,
        plannedMinutes: item.category.recommendedSessionMinutes,
        onComplete: { session in
            handleSessionComplete(session: session)
            showingActiveSession = false
        }
    )
}
```

### 2d. handleSessionComplete メソッド追加

```swift
private func handleSessionComplete(session: StudySession) {
    let engine = SpacedRepetitionEngine()
    engine.updateItemAfterSession(item: item, session: session)

    if let analytics = todayAnalytics {
        analytics.recordSession(session, category: item.category)
    } else {
        let newAnalytics = LearningAnalytics(date: Date())
        modelContext.insert(newAnalytics)
        newAnalytics.recordSession(session, category: item.category)
    }

    todayPlan?.markItemCompleted(item.id, minutes: session.actualMinutes, isMorning: session.isMorningSession)
    try? modelContext.save()
}
```

---

## Step 3: SessionView.swift — 既存セッション完了のサービス統合

SessionView の `onComplete` コールバックにもサービス統合を追加する（現在は `isSessionActive = false` のみ）。

### 3a. @Query 追加

```swift
@Query(sort: \LearningAnalytics.date, order: .reverse) private var analytics: [LearningAnalytics]
@Query(sort: \StudyPlan.date, order: .reverse) private var plans: [StudyPlan]
```

Computed property追加:
```swift
private var todayAnalytics: LearningAnalytics? {
    let today = Calendar.current.startOfDay(for: Date())
    return analytics.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
}
private var todayPlan: StudyPlan? {
    plans.first { Calendar.current.isDateInToday($0.date) }
}
```

### 3b. fullScreenCover の onComplete 変更（行149-160）

```swift
onComplete: { session in
    handleSessionComplete(session: session, item: item)
    isSessionActive = false
}
```

### 3c. handleSessionComplete メソッド追加

DashboardViewと同じパターン。

---

## 技術的な注意事項

- **ActiveSessionView 内の既存処理との重複なし**: ActiveSessionView は `studyItem.recordSession()` と `session.complete()` を実行済み。onCompleteで追加するのは SM-2更新 / Analytics記録 / Plan更新の3つで重複しない
- **SpacedRepetitionEngine は Sendable**: View内で `let engine = SpacedRepetitionEngine()` で即座にインスタンス化して使える
- **@MainActor 制約**: View の private func 内なので暗黙的に @MainActor。SwiftData 操作も問題なし
- **LearningAnalytics 新規作成**: 今日のデータが未存在の場合は `modelContext.insert()` で新規作成

## 参照するが変更しないファイル

- `Services/SpacedRepetitionEngine.swift` — `updateItemAfterSession(item:session:)` (行127-139)
- `Models/LearningAnalytics.swift` — `recordSession(_:category:)` (行133-157)
- `Models/StudyPlan.swift` — `markItemCompleted(_:minutes:isMorning:)` (行128-145)
- `Views/Session/SessionView.swift` — `ActiveSessionView`, `SessionCompleteView` (再利用)

## 検証方法

1. `cd Apps/AsaStudyPlanner && xcodegen generate`
2. `xcodebuild -project AsaStudyPlanner.xcodeproj -scheme AsaStudyPlanner -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
3. ビルドエラー0件を確認
4. 既存テスト: `xcodebuild test -project AsaStudyPlanner.xcodeproj -scheme AsaStudyPlannerTests -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
