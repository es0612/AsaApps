//
//  ProgressiveOverloadServiceTests.swift
//  AsaFitnessCoachTests
//
//  プログレッシブオーバーロードサービスのテスト
//

import Testing
import Foundation
@testable import AsaFitnessCoach

@Suite("ProgressiveOverloadService Tests")
struct ProgressiveOverloadServiceTests {
    // MARK: - 基本テスト

    @Test("セッションがない場合はnilを返す")
    func testNoSessionsReturnsNil() async throws {
        let service = ProgressiveOverloadService()

        let suggestion = service.suggestWeightIncrease(
            for: "ベンチプレス",
            sessions: []
        )

        #expect(suggestion == nil)
    }

    @Test("対象エクササイズがない場合はnilを返す")
    func testNoMatchingExerciseReturnsNil() async throws {
        let service = ProgressiveOverloadService()
        let sessions = createTestSessions(exerciseName: "スクワット", weight: 60)

        let suggestion = service.suggestWeightIncrease(
            for: "ベンチプレス",
            sessions: sessions
        )

        #expect(suggestion == nil)
    }

    // MARK: - 提案生成テスト

    @Test("高完了率で標準増加を提案")
    func testHighCompletionRateSuggestsStandardIncrease() async throws {
        let service = ProgressiveOverloadService()
        let sessions = createHighPerformanceSessions(weight: 50)

        let suggestion = service.suggestWeightIncrease(
            for: "ベンチプレス",
            sessions: sessions
        )

        #expect(suggestion != nil)
        #expect(suggestion!.suggestedWeight > 50)
        #expect(suggestion!.increasePercentage > 0)
    }

    @Test("低完了率で現状維持を提案")
    func testLowCompletionRateSuggestsMaintain() async throws {
        let service = ProgressiveOverloadService()
        let sessions = createLowPerformanceSessions(weight: 50)

        let suggestion = service.suggestWeightIncrease(
            for: "ベンチプレス",
            sessions: sessions
        )

        #expect(suggestion != nil)
        #expect(suggestion!.increasePercentage == 0)
    }

    // MARK: - 信頼度テスト

    @Test("十分なデータで高信頼度")
    func testSufficientDataHighConfidence() async throws {
        let service = ProgressiveOverloadService()
        let sessions = createMultipleSessions(count: 5, weight: 50)

        let suggestion = service.suggestWeightIncrease(
            for: "ベンチプレス",
            sessions: sessions
        )

        #expect(suggestion != nil)
        #expect(suggestion!.confidence == .high)
    }

    @Test("データ不足で低信頼度")
    func testInsufficientDataLowConfidence() async throws {
        let service = ProgressiveOverloadService()
        let sessions = createMultipleSessions(count: 1, weight: 50)

        let suggestion = service.suggestWeightIncrease(
            for: "ベンチプレス",
            sessions: sessions
        )

        #expect(suggestion != nil)
        #expect(suggestion!.confidence == .low)
    }

    // MARK: - 重量丸めテスト

    @Test("重量が2.5kg単位に丸められる")
    func testWeightRoundedTo2_5kg() async throws {
        let service = ProgressiveOverloadService()
        let sessions = createHighPerformanceSessions(weight: 51)

        let suggestion = service.suggestWeightIncrease(
            for: "ベンチプレス",
            sessions: sessions
        )

        #expect(suggestion != nil)
        // 2.5で割って余りがないことを確認
        let remainder = suggestion!.suggestedWeight.truncatingRemainder(dividingBy: 2.5)
        #expect(remainder == 0 || remainder == 2.5)
    }

    // MARK: - 複数エクササイズテスト

    @Test("複数エクササイズの提案を生成")
    func testMultipleExerciseSuggestions() async throws {
        let service = ProgressiveOverloadService()
        var sessions: [WorkoutSession] = []

        // 複数のエクササイズを含むセッションを作成
        sessions.append(contentsOf: createTestSessions(exerciseName: "ベンチプレス", weight: 50))
        sessions.append(contentsOf: createTestSessions(exerciseName: "スクワット", weight: 80))

        let suggestions = service.suggestAllWeightIncreases(sessions: sessions)

        #expect(suggestions.count >= 2)
    }

    // MARK: - 表示文字列テスト

    @Test("表示用文字列が正しく生成される")
    func testDisplayStrings() async throws {
        let suggestion = ProgressiveOverloadSuggestion(
            exerciseName: "ベンチプレス",
            currentWeight: 50,
            suggestedWeight: 52.5,
            increasePercentage: 5,
            reason: "テスト理由",
            confidence: .high
        )

        #expect(suggestion.displayIncrease == "+5.0%")
        #expect(suggestion.displayWeightChange == "50.0kg → 52.5kg")
    }

    // MARK: - ヘルパーメソッド

    private func createTestSessions(exerciseName: String, weight: Double) -> [WorkoutSession] {
        let session = WorkoutSession(planName: "テストプラン")
        session.isCompleted = true

        var completedExercise = CompletedExercise(
            exerciseId: UUID(),
            exerciseName: exerciseName,
            isCompleted: true
        )

        completedExercise.actualSets = [
            SetRecord(setNumber: 1, reps: 10, weight: weight, isCompleted: true),
            SetRecord(setNumber: 2, reps: 10, weight: weight, isCompleted: true),
            SetRecord(setNumber: 3, reps: 10, weight: weight, isCompleted: true)
        ]
        completedExercise.formQuality = .good

        session.completedExercises = [completedExercise]
        return [session]
    }

    private func createHighPerformanceSessions(weight: Double) -> [WorkoutSession] {
        var sessions: [WorkoutSession] = []

        for i in 0..<3 {
            let session = WorkoutSession(planName: "テストプラン")
            session.startTime = Date().addingTimeInterval(Double(-i) * 86400 * 2)
            session.isCompleted = true

            var completedExercise = CompletedExercise(
                exerciseId: UUID(),
                exerciseName: "ベンチプレス",
                isCompleted: true
            )

            completedExercise.actualSets = [
                SetRecord(setNumber: 1, reps: 10, weight: weight, isCompleted: true),
                SetRecord(setNumber: 2, reps: 10, weight: weight, isCompleted: true),
                SetRecord(setNumber: 3, reps: 10, weight: weight, isCompleted: true)
            ]
            completedExercise.formQuality = .excellent

            session.completedExercises = [completedExercise]
            sessions.append(session)
        }

        return sessions
    }

    private func createLowPerformanceSessions(weight: Double) -> [WorkoutSession] {
        var sessions: [WorkoutSession] = []

        for i in 0..<3 {
            let session = WorkoutSession(planName: "テストプラン")
            session.startTime = Date().addingTimeInterval(Double(-i) * 86400 * 2)
            session.isCompleted = true

            var completedExercise = CompletedExercise(
                exerciseId: UUID(),
                exerciseName: "ベンチプレス",
                isCompleted: true
            )

            // 低い完了率をシミュレート（3セット中1セットのみ完了）
            completedExercise.actualSets = [
                SetRecord(setNumber: 1, reps: 6, weight: weight, isCompleted: true),
                SetRecord(setNumber: 2, reps: 4, weight: weight, isCompleted: false),
                SetRecord(setNumber: 3, reps: 0, weight: weight, isCompleted: false)
            ]
            completedExercise.formQuality = .poor

            session.completedExercises = [completedExercise]
            sessions.append(session)
        }

        return sessions
    }

    private func createMultipleSessions(count: Int, weight: Double) -> [WorkoutSession] {
        var sessions: [WorkoutSession] = []

        for i in 0..<count {
            let session = WorkoutSession(planName: "テストプラン")
            session.startTime = Date().addingTimeInterval(Double(-i) * 86400 * 2)
            session.isCompleted = true

            var completedExercise = CompletedExercise(
                exerciseId: UUID(),
                exerciseName: "ベンチプレス",
                isCompleted: true
            )

            completedExercise.actualSets = [
                SetRecord(setNumber: 1, reps: 10, weight: weight, isCompleted: true),
                SetRecord(setNumber: 2, reps: 10, weight: weight, isCompleted: true),
                SetRecord(setNumber: 3, reps: 10, weight: weight, isCompleted: true)
            ]
            completedExercise.formQuality = .good

            session.completedExercises = [completedExercise]
            sessions.append(session)
        }

        return sessions
    }
}
