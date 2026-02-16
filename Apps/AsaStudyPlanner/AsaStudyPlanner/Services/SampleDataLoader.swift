import Foundation
import SwiftData

#if DEBUG
/// デモ用サンプルデータローダー
/// シミュレータでのデモ動画撮影用にリアルなデータを投入する
enum SampleDataLoader {

    @MainActor
    static func loadIfNeeded(context: ModelContext) {
        // 既にデータがある場合はスキップ
        let descriptor = FetchDescriptor<StudyItem>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        loadSampleData(context: context)
    }

    @MainActor
    static func loadSampleData(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        // MARK: - 学習項目の作成

        let swift = StudyItem(
            title: "Swift並行処理マスター",
            description: "async/await、Actor、Sendableの完全理解。Task groupやAsyncSequenceも含む",
            category: .programming,
            difficulty: .hard,
            estimatedMinutes: 120,
            targetDate: calendar.date(byAdding: .day, value: 14, to: now)
        )
        swift.masteryLevel = 0.65
        swift.totalStudyMinutes = 285
        swift.sessionCount = 8
        swift.aiPriorityScore = 0.92
        swift.aiConfidenceScore = 0.87
        swift.aiReasons = ["期限が近い", "高難易度のため朝活推奨", "前回セッションから3日経過"]
        swift.nextReviewDate = calendar.date(byAdding: .day, value: -1, to: now) // 復習が必要
        swift.easeFactor = 2.3
        swift.repetitionCount = 4
        swift.lastIntervalDays = 4

        let toeic = StudyItem(
            title: "TOEIC 900点対策",
            description: "Part 5-7のリーディング強化、時間配分戦略の練習",
            category: .language,
            difficulty: .hard,
            estimatedMinutes: 90,
            targetDate: calendar.date(byAdding: .day, value: 30, to: now)
        )
        toeic.masteryLevel = 0.45
        toeic.totalStudyMinutes = 420
        toeic.sessionCount = 14
        toeic.aiPriorityScore = 0.78
        toeic.aiConfidenceScore = 0.82
        toeic.aiReasons = ["試験まで30日", "リーディング正答率が伸び悩み"]
        toeic.nextReviewDate = calendar.date(byAdding: .hour, value: 2, to: now) // 今日復習予定
        toeic.easeFactor = 2.1
        toeic.repetitionCount = 6
        toeic.lastIntervalDays = 3

        let aws = StudyItem(
            title: "AWS SAA資格取得",
            description: "Solutions Architect Associate試験対策。VPC、IAM、S3、Lambda中心",
            category: .certification,
            difficulty: .expert,
            estimatedMinutes: 180,
            targetDate: calendar.date(byAdding: .day, value: 21, to: now)
        )
        aws.masteryLevel = 0.35
        aws.totalStudyMinutes = 340
        aws.sessionCount = 10
        aws.aiPriorityScore = 0.85
        aws.aiConfidenceScore = 0.79
        aws.aiReasons = ["資格試験が近い", "上級難易度", "習熟度がまだ不十分"]
        aws.nextReviewDate = calendar.date(byAdding: .day, value: 1, to: now)
        aws.easeFactor = 2.0
        aws.repetitionCount = 3
        aws.lastIntervalDays = 5

        let swiftui = StudyItem(
            title: "SwiftUI アニメーション",
            description: "matchedGeometryEffect、PhaseAnimator、カスタムTransitionの実装",
            category: .programming,
            difficulty: .medium,
            estimatedMinutes: 60,
            targetDate: calendar.date(byAdding: .day, value: 7, to: now)
        )
        swiftui.masteryLevel = 0.52
        swiftui.totalStudyMinutes = 150
        swiftui.sessionCount = 5
        swiftui.aiPriorityScore = 0.72
        swiftui.aiConfidenceScore = 0.75
        swiftui.aiReasons = ["期限まで1週間", "実践プロジェクトに応用可能"]
        swiftui.nextReviewDate = calendar.date(byAdding: .day, value: -2, to: now) // 復習遅延
        swiftui.easeFactor = 2.5
        swiftui.repetitionCount = 2
        swiftui.lastIntervalDays = 6

        let math = StudyItem(
            title: "線形代数の基礎",
            description: "行列演算、固有値分解、ML前提知識として",
            category: .mathematics,
            difficulty: .hard,
            estimatedMinutes: 90
        )
        math.masteryLevel = 0.22
        math.totalStudyMinutes = 80
        math.sessionCount = 3
        math.aiPriorityScore = 0.55
        math.aiConfidenceScore = 0.68
        math.aiReasons = ["ML学習の前提知識", "朝の集中時間に最適"]
        math.easeFactor = 2.5
        math.repetitionCount = 1
        math.lastIntervalDays = 1
        math.nextReviewDate = calendar.date(byAdding: .day, value: 2, to: now)

        let design = StudyItem(
            title: "UIデザイン原則",
            description: "色彩理論、タイポグラフィ、レイアウトの基本原則",
            category: .creative,
            difficulty: .easy,
            estimatedMinutes: 45
        )
        design.masteryLevel = 0.78
        design.totalStudyMinutes = 210
        design.sessionCount = 7
        design.aiPriorityScore = 0.38
        design.aiConfidenceScore = 0.90
        design.aiReasons = ["習熟度が高い", "復習間隔を広げてOK"]
        design.nextReviewDate = calendar.date(byAdding: .day, value: 10, to: now)
        design.easeFactor = 2.8
        design.repetitionCount = 5
        design.lastIntervalDays = 14

        let accounting = StudyItem(
            title: "簿記3級",
            description: "仕訳、決算整理、財務諸表の読み方",
            category: .business,
            difficulty: .medium,
            estimatedMinutes: 60,
            targetDate: calendar.date(byAdding: .day, value: 45, to: now)
        )
        accounting.masteryLevel = 0.15
        accounting.totalStudyMinutes = 45
        accounting.sessionCount = 2
        accounting.aiPriorityScore = 0.48
        accounting.aiConfidenceScore = 0.60
        accounting.aiReasons = ["まだ学習初期段階", "試験まで時間あり"]
        accounting.easeFactor = 2.5
        accounting.repetitionCount = 1
        accounting.lastIntervalDays = 1

        let items = [swift, toeic, aws, swiftui, math, design, accounting]
        items.forEach { context.insert($0) }

        // MARK: - 今日の学習セッション（朝活済み）

        let morningTime = calendar.date(bySettingHour: 5, minute: 30, second: 0, of: now)!

        let session1 = StudySession(
            studyItemId: swift.id,
            plannedMinutes: 50,
            startedAt: morningTime
        )
        session1.endedAt = calendar.date(byAdding: .minute, value: 48, to: morningTime)
        session1.actualMinutes = 48
        session1.focusLevel = 5
        session1.comprehensionLevel = 4
        session1.notes = "Actorの排他制御が理解できた。次はAsyncSequence"
        session1.isCompleted = true
        session1.isEarlyMorning = true
        session1.isMorningSession = true
        session1.startHour = 5

        let session2Start = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: now)!
        let session2 = StudySession(
            studyItemId: aws.id,
            plannedMinutes: 45,
            startedAt: session2Start
        )
        session2.endedAt = calendar.date(byAdding: .minute, value: 42, to: session2Start)
        session2.actualMinutes = 42
        session2.focusLevel = 4
        session2.comprehensionLevel = 3
        session2.notes = "VPCサブネット構成の問題を10問解いた"
        session2.isCompleted = true
        session2.isEarlyMorning = true
        session2.isMorningSession = true
        session2.startHour = 6

        // 昨日のセッション
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let yesterdayMorning = calendar.date(bySettingHour: 5, minute: 45, second: 0, of: yesterday)!

        let session3 = StudySession(
            studyItemId: toeic.id,
            plannedMinutes: 30,
            startedAt: yesterdayMorning
        )
        session3.endedAt = calendar.date(byAdding: .minute, value: 30, to: yesterdayMorning)
        session3.actualMinutes = 30
        session3.focusLevel = 4
        session3.comprehensionLevel = 4
        session3.isCompleted = true
        session3.isEarlyMorning = true
        session3.isMorningSession = true
        session3.startHour = 5

        let sessions = [session1, session2, session3]
        sessions.forEach { context.insert($0) }

        // MARK: - 今日のLearningAnalytics

        let todayAnalytics = LearningAnalytics(date: now)
        todayAnalytics.totalMinutes = 90
        todayAnalytics.completedSessions = 2
        todayAnalytics.morningMinutes = 90
        todayAnalytics.earlyMorningMinutes = 90
        todayAnalytics.averageFocusLevel = 4.5
        todayAnalytics.averageComprehensionLevel = 3.5
        todayAnalytics.streakDays = 12
        todayAnalytics.morningStreakDays = 8
        todayAnalytics.categoryMinutes = [
            StudyCategory.programming.rawValue: 48,
            StudyCategory.certification.rawValue: 42
        ]
        todayAnalytics.aiAcceptedCount = 3
        todayAnalytics.aiRejectedCount = 1
        context.insert(todayAnalytics)

        // 昨日のAnalytics
        let yesterdayAnalytics = LearningAnalytics(date: yesterday)
        yesterdayAnalytics.totalMinutes = 75
        yesterdayAnalytics.completedSessions = 3
        yesterdayAnalytics.morningMinutes = 60
        yesterdayAnalytics.earlyMorningMinutes = 30
        yesterdayAnalytics.averageFocusLevel = 4.0
        yesterdayAnalytics.averageComprehensionLevel = 3.7
        yesterdayAnalytics.streakDays = 11
        yesterdayAnalytics.morningStreakDays = 7
        yesterdayAnalytics.categoryMinutes = [
            StudyCategory.language.rawValue: 30,
            StudyCategory.programming.rawValue: 25,
            StudyCategory.certification.rawValue: 20
        ]
        context.insert(yesterdayAnalytics)

        // MARK: - 今日のStudyPlan

        let morningStart = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: now)
        let todayPlan = StudyPlan(
            date: now,
            plannedItemIds: [swift.id, aws.id, toeic.id, swiftui.id],
            totalPlannedMinutes: 150,
            morningGoalMinutes: 90,
            morningStartTime: morningStart
        )
        todayPlan.completedItemIds = [swift.id, aws.id]
        todayPlan.actualTotalMinutes = 90
        todayPlan.morningActualMinutes = 90
        todayPlan.completionRate = 0.5
        todayPlan.optimizationScore = 0.82
        context.insert(todayPlan)

        // MARK: - UserLearningProfile

        let profile = UserLearningProfile()
        context.insert(profile)

        try? context.save()
    }
}
#endif
