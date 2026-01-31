//
//  ReviewViewModel.swift
//  AsaLanguageLearn
//
//  復習画面のViewModel
//

import Foundation
import SwiftData

/// 復習画面のViewModel
@MainActor
@Observable
final class ReviewViewModel {
    // MARK: - Properties

    /// 復習対象アイテム
    private(set) var itemsToReview: [LearningItem] = []

    /// 現在のインデックス
    private(set) var currentIndex: Int = 0

    /// 復習完了したアイテム
    private(set) var completedItems: [LearningItem] = []

    /// セッション統計
    private(set) var correctCount: Int = 0
    private(set) var incorrectCount: Int = 0

    /// ローディング状態
    private(set) var isLoading = false

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Computed Properties

    var currentItem: LearningItem? {
        guard currentIndex < itemsToReview.count else { return nil }
        return itemsToReview[currentIndex]
    }

    var totalItems: Int {
        itemsToReview.count
    }

    var progress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(currentIndex) / Double(totalItems)
    }

    var isCompleted: Bool {
        currentIndex >= itemsToReview.count
    }

    var remainingItems: Int {
        max(0, totalItems - currentIndex)
    }

    /// 習熟レベル別のカウント
    var masteryLevelCounts: [MasteryLevel: Int] {
        SRSCalculator.countByMasteryLevel(itemsToReview)
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// 復習対象アイテムをロード
    func loadItemsForReview() async {
        isLoading = true

        do {
            let descriptor = FetchDescriptor<LearningItem>()
            let allItems = try modelContext.fetch(descriptor)

            // 復習が必要なアイテムをフィルタ
            let dueItems = allItems.filter { item in
                guard let progress = item.progress else { return false }
                return progress.needsReview
            }

            // 優先度順にソート
            itemsToReview = dueItems.sorted { item1, item2 in
                let priority1 = SRSCalculator.calculateReviewPriority(
                    nextReviewDate: item1.progress?.nextReviewDate,
                    correctRate: item1.progress?.correctRate ?? 0
                )
                let priority2 = SRSCalculator.calculateReviewPriority(
                    nextReviewDate: item2.progress?.nextReviewDate,
                    correctRate: item2.progress?.correctRate ?? 0
                )
                return priority1 > priority2
            }

            currentIndex = 0
            completedItems = []
            correctCount = 0
            incorrectCount = 0

        } catch {
            print("復習アイテムの読み込みに失敗: \(error)")
        }

        isLoading = false
    }

    /// 特定のレッスンの復習アイテムをロード
    func loadItemsForReview(from lesson: Lesson) {
        itemsToReview = lesson.items.filter { item in
            guard let progress = item.progress else { return false }
            return progress.needsReview
        }.sorted { item1, item2 in
            let priority1 = SRSCalculator.calculateReviewPriority(
                nextReviewDate: item1.progress?.nextReviewDate,
                correctRate: item1.progress?.correctRate ?? 0
            )
            let priority2 = SRSCalculator.calculateReviewPriority(
                nextReviewDate: item2.progress?.nextReviewDate,
                correctRate: item2.progress?.correctRate ?? 0
            )
            return priority1 > priority2
        }

        currentIndex = 0
        completedItems = []
        correctCount = 0
        incorrectCount = 0
    }

    // MARK: - Actions

    /// 正解を記録
    func recordCorrect(pronunciationScore: Double) {
        guard let item = currentItem else { return }

        item.progress?.recordCorrect(pronunciationScore: pronunciationScore)
        correctCount += 1
        completedItems.append(item)

        try? modelContext.save()

        moveToNext()
    }

    /// 不正解を記録
    func recordIncorrect(pronunciationScore: Double) {
        guard let item = currentItem else { return }

        item.progress?.recordIncorrect(pronunciationScore: pronunciationScore)
        incorrectCount += 1
        completedItems.append(item)

        try? modelContext.save()

        moveToNext()
    }

    /// 次のアイテムへ
    private func moveToNext() {
        currentIndex += 1
    }

    /// セッションをリセット
    func reset() {
        currentIndex = 0
        completedItems = []
        correctCount = 0
        incorrectCount = 0
    }

    /// 統計サマリー
    var sessionSummary: ReviewSessionSummary {
        ReviewSessionSummary(
            totalItems: completedItems.count,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            masteryLevelChanges: calculateMasteryChanges()
        )
    }

    private func calculateMasteryChanges() -> [MasteryLevel: Int] {
        var changes: [MasteryLevel: Int] = [:]
        for level in MasteryLevel.allCases {
            changes[level] = 0
        }

        for item in completedItems {
            if let level = item.progress?.masteryLevel {
                changes[level, default: 0] += 1
            }
        }

        return changes
    }
}

// MARK: - Review Session Summary

struct ReviewSessionSummary {
    let totalItems: Int
    let correctCount: Int
    let incorrectCount: Int
    let masteryLevelChanges: [MasteryLevel: Int]

    var correctRate: Double {
        guard totalItems > 0 else { return 0 }
        return Double(correctCount) / Double(totalItems)
    }

    var correctRateText: String {
        String(format: "%.0f%%", correctRate * 100)
    }
}
