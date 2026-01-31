//
//  DashboardViewModel.swift
//  AsaLanguageLearn
//
//  ダッシュボード画面のViewModel
//

import Foundation
import SwiftData

/// ダッシュボードViewModel
@MainActor
@Observable
final class DashboardViewModel {
    // MARK: - Properties

    /// ユーザープロファイル
    private(set) var userProfile: UserProfile?

    /// 今日の統計
    private(set) var todayStats: DailyStats?

    /// 週間データ
    private(set) var weeklyData: [DailyStats] = []

    /// 習熟レベル別アイテム数
    private(set) var masteryLevelCounts: [MasteryLevel: Int] = [:]

    /// 復習待ちアイテム数
    private(set) var dueItemsCount: Int = 0

    /// ローディング状態
    private(set) var isLoading = false

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Computed Properties

    var totalStudyTimeText: String {
        userProfile?.totalStudyTimeText ?? "0分"
    }

    var currentStreak: Int {
        userProfile?.currentStreak ?? 0
    }

    var bestStreak: Int {
        userProfile?.bestStreak ?? 0
    }

    var overallAccuracy: Double {
        userProfile?.overallAccuracy ?? 0
    }

    var accuracyText: String {
        userProfile?.accuracyText ?? "0%"
    }

    var masteredItemsCount: Int {
        userProfile?.masteredItems ?? 0
    }

    var completedLessonsCount: Int {
        userProfile?.completedLessons ?? 0
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// データをロード
    func loadData() async {
        isLoading = true

        do {
            // ユーザープロファイル
            let profileDescriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(profileDescriptor)
            userProfile = profiles.first

            // 学習アイテム統計
            let itemDescriptor = FetchDescriptor<LearningItem>()
            let allItems = try modelContext.fetch(itemDescriptor)

            // 習熟レベル別カウント
            masteryLevelCounts = SRSCalculator.countByMasteryLevel(allItems)

            // 復習待ちカウント
            dueItemsCount = SRSCalculator.countDueForReview(allItems)

            // セッション履歴から週間データを生成
            weeklyData = await generateWeeklyData()

            // 今日の統計
            todayStats = weeklyData.last

        } catch {
            print("ダッシュボードデータの読み込みに失敗: \(error)")
        }

        isLoading = false
    }

    /// 週間データを生成
    private func generateWeeklyData() async -> [DailyStats] {
        var stats: [DailyStats] = []
        let calendar = Calendar.current

        // 過去7日分のデータを生成
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                continue
            }

            do {
                // その日のセッションを取得
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

                let predicate = #Predicate<StudySession> { session in
                    session.startedAt >= startOfDay && session.startedAt < endOfDay
                }

                let descriptor = FetchDescriptor<StudySession>(
                    predicate: predicate
                )

                let sessions = try modelContext.fetch(descriptor)

                // 統計を集計
                let totalItems = sessions.reduce(0) { $0 + $1.itemsPracticed }
                let correctItems = sessions.reduce(0) { $0 + $1.correctCount }
                let totalDuration = sessions.reduce(0) { $0 + $1.durationSeconds }
                let avgScore = sessions.isEmpty ? 0 : sessions.reduce(0.0) { $0 + $1.averageScore } / Double(sessions.count)

                let dailyStats = DailyStats(
                    date: date,
                    itemsPracticed: totalItems,
                    correctCount: correctItems,
                    studyDurationSeconds: totalDuration,
                    averageScore: avgScore
                )

                stats.append(dailyStats)

            } catch {
                // エラー時はダミーデータ
                stats.append(DailyStats(
                    date: date,
                    itemsPracticed: 0,
                    correctCount: 0,
                    studyDurationSeconds: 0,
                    averageScore: 0
                ))
            }
        }

        return stats
    }

    /// データを更新
    func refresh() async {
        await loadData()
    }
}

// MARK: - Daily Stats

struct DailyStats: Identifiable {
    let id = UUID()
    let date: Date
    let itemsPracticed: Int
    let correctCount: Int
    let studyDurationSeconds: Int
    let averageScore: Double

    var correctRate: Double {
        guard itemsPracticed > 0 else { return 0 }
        return Double(correctCount) / Double(itemsPracticed)
    }

    var studyDurationMinutes: Int {
        studyDurationSeconds / 60
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
