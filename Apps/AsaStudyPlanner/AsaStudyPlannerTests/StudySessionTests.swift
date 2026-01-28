import Testing
import Foundation
@testable import AsaStudyPlanner

@Suite("StudySession モデルテスト")
struct StudySessionTests {

    // MARK: - 初期化テスト

    @Test("デフォルト値で正しく初期化される")
    func testDefaultInitialization() {
        let itemId = UUID()
        let session = StudySession(studyItemId: itemId)

        #expect(session.studyItemId == itemId)
        #expect(session.plannedMinutes == 25)
        #expect(session.actualMinutes == 0)
        #expect(session.focusLevel == 3)
        #expect(session.comprehensionLevel == 3)
        #expect(session.isCompleted == false)
        #expect(session.wasInterrupted == false)
    }

    @Test("カスタム時間で正しく初期化される")
    func testCustomInitialization() {
        let itemId = UUID()
        let session = StudySession(studyItemId: itemId, plannedMinutes: 45)

        #expect(session.plannedMinutes == 45)
    }

    // MARK: - 時間帯判定テスト

    @Test("朝活時間帯（5-7時）が正しく判定される")
    func testEarlyMorningDetection() {
        let calendar = Calendar.current
        var components = calendar.dateComponents(in: .current, from: Date())
        components.hour = 6
        components.minute = 0

        let morningTime = calendar.date(from: components)!
        let session = StudySession(studyItemId: UUID(), startedAt: morningTime)

        #expect(session.isEarlyMorning == true)
        #expect(session.isMorningSession == true)
        #expect(session.startHour == 6)
    }

    @Test("朝の時間帯（7-9時）が正しく判定される")
    func testMorningDetection() {
        let calendar = Calendar.current
        var components = calendar.dateComponents(in: .current, from: Date())
        components.hour = 8
        components.minute = 0

        let morningTime = calendar.date(from: components)!
        let session = StudySession(studyItemId: UUID(), startedAt: morningTime)

        #expect(session.isEarlyMorning == false)
        #expect(session.isMorningSession == true)
    }

    @Test("午後の時間帯が正しく判定される")
    func testAfternoonDetection() {
        let calendar = Calendar.current
        var components = calendar.dateComponents(in: .current, from: Date())
        components.hour = 14
        components.minute = 0

        let afternoonTime = calendar.date(from: components)!
        let session = StudySession(studyItemId: UUID(), startedAt: afternoonTime)

        #expect(session.isEarlyMorning == false)
        #expect(session.isMorningSession == false)
    }

    // MARK: - セッション完了テスト

    @Test("セッション完了が正しく動作する")
    func testCompleteSession() {
        let session = StudySession(studyItemId: UUID(), plannedMinutes: 25)

        session.complete(focusLevel: 4, comprehensionLevel: 5, notes: "よく理解できた")

        #expect(session.isCompleted == true)
        #expect(session.focusLevel == 4)
        #expect(session.comprehensionLevel == 5)
        #expect(session.notes == "よく理解できた")
        #expect(session.endedAt != nil)
    }

    @Test("集中度・理解度の範囲制限が動作する")
    func testRatingBounds() {
        let session = StudySession(studyItemId: UUID())

        // 上限を超える値
        session.complete(focusLevel: 10, comprehensionLevel: 10)
        #expect(session.focusLevel == 5)
        #expect(session.comprehensionLevel == 5)

        // 下限を下回る値
        let session2 = StudySession(studyItemId: UUID())
        session2.complete(focusLevel: 0, comprehensionLevel: -1)
        #expect(session2.focusLevel == 1)
        #expect(session2.comprehensionLevel == 1)
    }

    // MARK: - セッション中断テスト

    @Test("セッション中断が正しく動作する")
    func testInterruptSession() {
        let session = StudySession(studyItemId: UUID())

        session.interrupt()

        #expect(session.wasInterrupted == true)
        #expect(session.isCompleted == false)
        #expect(session.endedAt != nil)
    }

    // MARK: - 品質スコアテスト

    @Test("品質スコアが正しく計算される")
    func testQualityScore() {
        let session = StudySession(studyItemId: UUID())

        session.complete(focusLevel: 5, comprehensionLevel: 5)
        #expect(session.qualityScore == 5)

        let session2 = StudySession(studyItemId: UUID())
        session2.complete(focusLevel: 3, comprehensionLevel: 3)
        #expect(session2.qualityScore == 3)

        let session3 = StudySession(studyItemId: UUID())
        session3.complete(focusLevel: 4, comprehensionLevel: 2)
        #expect(session3.qualityScore == 3)
    }

    // MARK: - 朝活ボーナステスト

    @Test("朝活ボーナスが正しく計算される")
    func testMorningBonus() {
        let calendar = Calendar.current

        // 深朝活（5-7時）
        var components = calendar.dateComponents(in: .current, from: Date())
        components.hour = 6
        let earlyMorning = calendar.date(from: components)!
        let earlySession = StudySession(studyItemId: UUID(), startedAt: earlyMorning)
        #expect(earlySession.morningBonus == 0.3)

        // 朝（7-9時）
        components.hour = 8
        let morning = calendar.date(from: components)!
        let morningSession = StudySession(studyItemId: UUID(), startedAt: morning)
        #expect(morningSession.morningBonus == 0.15)

        // 午後
        components.hour = 14
        let afternoon = calendar.date(from: components)!
        let afternoonSession = StudySession(studyItemId: UUID(), startedAt: afternoon)
        #expect(afternoonSession.morningBonus == 0.0)
    }

    // MARK: - 効率テスト

    @Test("セッション効率が正しく計算される")
    func testEfficiency() {
        let session = StudySession(studyItemId: UUID(), plannedMinutes: 30)
        session.actualMinutes = 30
        #expect(session.efficiency == 1.0)

        let session2 = StudySession(studyItemId: UUID(), plannedMinutes: 30)
        session2.actualMinutes = 15
        #expect(session2.efficiency == 0.5)

        let session3 = StudySession(studyItemId: UUID(), plannedMinutes: 0)
        #expect(session3.efficiency == 0.0)
    }
}
