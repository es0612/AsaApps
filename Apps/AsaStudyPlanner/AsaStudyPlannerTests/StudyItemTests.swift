import Testing
import Foundation
@testable import AsaStudyPlanner

@Suite("StudyItem モデルテスト")
struct StudyItemTests {

    // MARK: - 初期化テスト

    @Test("デフォルト値で正しく初期化される")
    func testDefaultInitialization() {
        let item = StudyItem(title: "Swift学習")

        #expect(item.title == "Swift学習")
        #expect(item.category == .other)
        #expect(item.difficulty == .medium)
        #expect(item.estimatedMinutes == 30)
        #expect(item.masteryLevel == 0.0)
        #expect(item.targetDate == nil)
        #expect(item.isCompleted == false)
        #expect(item.isArchived == false)
        #expect(item.totalStudyMinutes == 0)
        #expect(item.sessionCount == 0)
    }

    @Test("カスタム値で正しく初期化される")
    func testCustomInitialization() {
        let targetDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let item = StudyItem(
            title: "SwiftUI",
            description: "SwiftUIの基礎",
            category: .programming,
            difficulty: .hard,
            estimatedMinutes: 60,
            targetDate: targetDate
        )

        #expect(item.title == "SwiftUI")
        #expect(item.itemDescription == "SwiftUIの基礎")
        #expect(item.category == .programming)
        #expect(item.difficulty == .hard)
        #expect(item.estimatedMinutes == 60)
        #expect(item.targetDate != nil)
    }

    // MARK: - 習熟度テスト

    @Test("習熟度ラベルが正しく返される")
    func testMasteryLabel() {
        let item = StudyItem(title: "テスト")

        item.masteryLevel = 0.0
        #expect(item.masteryLabel == "初学者")

        item.masteryLevel = 0.3
        #expect(item.masteryLabel == "入門")

        item.masteryLevel = 0.5
        #expect(item.masteryLabel == "中級")

        item.masteryLevel = 0.7
        #expect(item.masteryLabel == "上級")

        item.masteryLevel = 0.9
        #expect(item.masteryLabel == "マスター")
    }

    // MARK: - 期限テスト

    @Test("期限までの日数が正しく計算される")
    func testDaysUntilTarget() {
        let item = StudyItem(title: "テスト")

        // 期限なし
        #expect(item.daysUntilTarget == nil)

        // 7日後
        item.targetDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        #expect(item.daysUntilTarget == 7)

        // 期限切れ
        item.targetDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        #expect(item.daysUntilTarget == -1)
        #expect(item.isOverdue == true)
    }

    @Test("期限切れ判定が正しく動作する")
    func testIsOverdue() {
        let item = StudyItem(title: "テスト")

        // 期限なし
        #expect(item.isOverdue == false)

        // 未来の期限
        item.targetDate = Date().addingTimeInterval(86400)
        #expect(item.isOverdue == false)

        // 過去の期限
        item.targetDate = Date().addingTimeInterval(-86400)
        #expect(item.isOverdue == true)
    }

    // MARK: - セッション記録テスト

    @Test("セッション記録で統計が更新される")
    func testRecordSession() {
        let item = StudyItem(title: "テスト", estimatedMinutes: 60)

        item.recordSession(durationMinutes: 30, quality: 4)

        #expect(item.totalStudyMinutes == 30)
        #expect(item.sessionCount == 1)
        #expect(item.masteryLevel > 0.0)
    }

    @Test("複数セッションで習熟度が累積する")
    func testMultipleSessions() {
        let item = StudyItem(title: "テスト", estimatedMinutes: 30)

        item.recordSession(durationMinutes: 30, quality: 5)
        let firstMastery = item.masteryLevel

        item.recordSession(durationMinutes: 30, quality: 5)
        let secondMastery = item.masteryLevel

        #expect(secondMastery > firstMastery)
        #expect(item.sessionCount == 2)
        #expect(item.totalStudyMinutes == 60)
    }

    @Test("習熟度は1.0を超えない")
    func testMasteryLevelCap() {
        let item = StudyItem(title: "テスト", estimatedMinutes: 10)

        for _ in 0..<20 {
            item.recordSession(durationMinutes: 10, quality: 5)
        }

        #expect(item.masteryLevel <= 1.0)
    }

    // MARK: - 完了テスト

    @Test("完了マークが正しく動作する")
    func testMarkAsCompleted() {
        let item = StudyItem(title: "テスト")

        item.markAsCompleted()

        #expect(item.isCompleted == true)
        #expect(item.completedAt != nil)
        #expect(item.masteryLevel == 1.0)
    }

    // MARK: - AI予測テスト

    @Test("AI予測結果が正しく適用される")
    func testApplyAIPrediction() {
        let item = StudyItem(title: "テスト")
        let reasons = ["📅 期限が近い", "📚 難易度が高い"]

        item.applyAIPrediction(score: 0.85, confidence: 0.9, reasons: reasons)

        #expect(item.aiPriorityScore == 0.85)
        #expect(item.aiConfidenceScore == 0.9)
        #expect(item.aiReasons.count == 2)
        #expect(item.aiReasons.first == "📅 期限が近い")
    }

    // MARK: - アーカイブテスト

    @Test("アーカイブが正しく動作する")
    func testArchive() {
        let item = StudyItem(title: "テスト")

        item.archive()

        #expect(item.isArchived == true)
    }
}
