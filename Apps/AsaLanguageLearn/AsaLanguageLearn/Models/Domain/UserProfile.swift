//
//  UserProfile.swift
//  AsaLanguageLearn
//
//  ユーザープロファイル
//

import Foundation
import SwiftData

/// ユーザープロファイル
/// 学習統計と設定情報
@Model
final class UserProfile {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID

    /// ユーザー名
    var userName: String

    /// 学習開始日
    var startedAt: Date

    /// 総学習時間（秒）
    var totalStudySeconds: Int

    /// 連続学習日数
    var currentStreak: Int

    /// 最高連続学習日数
    var bestStreak: Int

    /// 最終学習日
    var lastStudyDate: Date?

    /// 完了したレッスン数
    var completedLessons: Int

    /// 習得したアイテム数
    var masteredItems: Int

    /// 累計正解数
    var totalCorrect: Int

    /// 累計回答数
    var totalAnswers: Int

    /// 音声速度設定（0.3〜1.3）
    var speechRate: Double

    /// 1日の目標学習時間（分）
    var dailyGoalMinutes: Int

    /// 通知設定
    var notificationsEnabled: Bool

    /// 復習リマインダー時間
    var reminderHour: Int

    // MARK: - Computed Properties

    /// 総学習時間のフォーマット済み文字列
    var totalStudyTimeText: String {
        let hours = totalStudySeconds / 3600
        let minutes = (totalStudySeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    /// 全体正解率（0.0〜1.0）
    var overallAccuracy: Double {
        guard totalAnswers > 0 else { return 0.0 }
        return Double(totalCorrect) / Double(totalAnswers)
    }

    /// 正解率のパーセント表示
    var accuracyText: String {
        String(format: "%.0f%%", overallAccuracy * 100)
    }

    /// 今日の学習を完了しているか
    var hasStudiedToday: Bool {
        guard let lastStudyDate = lastStudyDate else { return false }
        return Calendar.current.isDateInToday(lastStudyDate)
    }

    /// 連続学習が途切れているか
    var isStreakBroken: Bool {
        guard let lastStudyDate = lastStudyDate else { return true }
        let calendar = Calendar.current
        if calendar.isDateInToday(lastStudyDate) {
            return false
        }
        if calendar.isDateInYesterday(lastStudyDate) {
            return false
        }
        return true
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        userName: String = "学習者"
    ) {
        self.id = id
        self.userName = userName
        self.startedAt = Date()
        self.totalStudySeconds = 0
        self.currentStreak = 0
        self.bestStreak = 0
        self.completedLessons = 0
        self.masteredItems = 0
        self.totalCorrect = 0
        self.totalAnswers = 0
        self.speechRate = 0.5
        self.dailyGoalMinutes = 10
        self.notificationsEnabled = true
        self.reminderHour = 8
    }

    // MARK: - Methods

    /// 学習結果を記録
    func recordStudy(correct: Int, total: Int, durationSeconds: Int) {
        totalCorrect += correct
        totalAnswers += total
        totalStudySeconds += durationSeconds

        // 連続学習日数の更新
        updateStreak()
    }

    /// 連続学習日数を更新
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastStudyDate {
            let lastDay = calendar.startOfDay(for: lastDate)

            if lastDay == today {
                // 今日すでに学習済み
                return
            } else if calendar.isDateInYesterday(lastDate) {
                // 昨日学習した → ストリーク継続
                currentStreak += 1
            } else {
                // 2日以上空いた → ストリークリセット
                currentStreak = 1
            }
        } else {
            // 初めての学習
            currentStreak = 1
        }

        bestStreak = max(bestStreak, currentStreak)
        lastStudyDate = Date()
    }

    /// レッスン完了を記録
    func recordLessonCompleted() {
        completedLessons += 1
    }

    /// アイテム習得を記録
    func recordItemMastered() {
        masteredItems += 1
    }
}

// MARK: - Sample Data

extension UserProfile {
    static var sample: UserProfile {
        let profile = UserProfile(userName: "太郎")
        profile.totalStudySeconds = 3600 * 5 + 1800  // 5時間30分
        profile.currentStreak = 7
        profile.bestStreak = 14
        profile.completedLessons = 12
        profile.masteredItems = 45
        profile.totalCorrect = 234
        profile.totalAnswers = 280
        profile.lastStudyDate = Date()
        return profile
    }
}
