//
//  ModelTests.swift
//  AsaFitnessCoachTests
//
//  データモデルのテスト
//

import Testing
import Foundation
@testable import AsaFitnessCoach

@Suite("Model Tests")
struct ModelTests {
    // MARK: - UserProfile Tests

    @Suite("UserProfile")
    struct UserProfileTests {
        @Test("BMI計算が正しい")
        func testBMICalculation() async throws {
            let profile = UserProfile(name: "テスト")
            profile.height = 170  // cm
            profile.weight = 70   // kg

            let bmi = profile.bmi

            #expect(bmi != nil)
            // BMI = 70 / (1.7 * 1.7) = 24.22
            #expect(abs(bmi! - 24.22) < 0.1)
        }

        @Test("BMIカテゴリが正しい")
        func testBMICategory() async throws {
            let profile = UserProfile(name: "テスト")
            profile.height = 170
            profile.weight = 70

            #expect(profile.bmiCategory == "標準")

            profile.weight = 50
            #expect(profile.bmiCategory == "低体重")

            profile.weight = 80
            #expect(profile.bmiCategory == "過体重")
        }

        @Test("年齢計算が正しい")
        func testAgeCalculation() async throws {
            let profile = UserProfile(name: "テスト")
            let calendar = Calendar.current
            let birthDate = calendar.date(byAdding: .year, value: -30, to: Date())

            profile.birthDate = birthDate

            #expect(profile.age == 30)
        }
    }

    // MARK: - Exercise Tests

    @Suite("Exercise")
    struct ExerciseTests {
        @Test("総ボリューム計算が正しい")
        func testTotalVolumeCalculation() async throws {
            let exercise = Exercise(name: "ベンチプレス", category: .chest)
            exercise.sets = 3
            exercise.reps = 10
            exercise.weight = 60

            #expect(exercise.totalVolume == 1800)  // 3 * 10 * 60
        }

        @Test("時間ベースエクササイズの判定")
        func testIsTimeBasedExercise() async throws {
            let repExercise = Exercise(name: "ベンチプレス", category: .chest)
            #expect(repExercise.isTimeBasedExercise == false)

            let timeExercise = Exercise(name: "プランク", category: .core)
            timeExercise.duration = 60
            #expect(timeExercise.isTimeBasedExercise == true)
        }

        @Test("推定時間計算が正しい")
        func testEstimatedDuration() async throws {
            let exercise = Exercise(name: "ベンチプレス", category: .chest)
            exercise.sets = 3
            exercise.reps = 10
            exercise.restTime = 60

            let estimated = exercise.estimatedDuration
            // 3セット × 10レップ × 3秒 = 90秒 + 2回の休憩 × 60秒 = 210秒
            #expect(estimated == 210)
        }

        @Test("エクササイズの複製が正しい")
        func testExerciseDuplication() async throws {
            let original = Exercise(name: "スクワット", category: .legs)
            original.weight = 80
            original.targetMuscles = [.quadriceps, .glutes]

            let duplicate = original.duplicate()

            #expect(duplicate.name == original.name)
            #expect(duplicate.weight == original.weight)
            #expect(duplicate.targetMuscles == original.targetMuscles)
            #expect(duplicate.id != original.id)
        }

        @Test("プログレッシブオーバーロード適用")
        func testProgressiveOverload() async throws {
            let exercise = Exercise(name: "ベンチプレス", category: .chest)
            exercise.weight = 50

            exercise.applyProgressiveOverload(percentage: 0.05)

            #expect(exercise.weight == 52.5)
        }
    }

    // MARK: - WorkoutPlan Tests

    @Suite("WorkoutPlan")
    struct WorkoutPlanTests {
        @Test("エクササイズ追加で推定時間が更新される")
        func testEstimatedDurationUpdates() async throws {
            let plan = WorkoutPlan(name: "テストプラン")

            let exercise = Exercise(name: "ベンチプレス", category: .chest)
            exercise.sets = 3
            exercise.reps = 10
            exercise.restTime = 60

            plan.addExercise(exercise)

            #expect(plan.estimatedDuration > 0)
        }

        @Test("今日スケジュールされているか判定")
        func testIsScheduledForToday() async throws {
            let plan = WorkoutPlan(name: "テストプラン")
            let today = WeekDay.today

            plan.scheduledDays = [today]
            #expect(plan.isScheduledForToday == true)

            plan.scheduledDays = []
            #expect(plan.isScheduledForToday == false)
        }

        @Test("プランの複製が正しい")
        func testPlanDuplication() async throws {
            let original = WorkoutPlan(name: "オリジナル", description: "テスト説明")
            original.scheduledDays = [.monday, .wednesday, .friday]

            let duplicate = original.duplicate()

            #expect(duplicate.name == "オリジナル (コピー)")
            #expect(duplicate.planDescription == original.planDescription)
            #expect(duplicate.scheduledDays == original.scheduledDays)
            #expect(duplicate.isAIGenerated == false)
        }
    }

    // MARK: - WorkoutSession Tests

    @Suite("WorkoutSession")
    struct WorkoutSessionTests {
        @Test("セッション時間計算が正しい")
        func testSessionDuration() async throws {
            let session = WorkoutSession(planName: "テスト")
            let startTime = Date()
            session.startTime = startTime
            session.endTime = startTime.addingTimeInterval(1800)  // 30分後

            // 浮動小数点の精度を考慮して近似比較
            #expect(abs(session.duration - 30) < 0.1)
        }

        @Test("完了率計算が正しい")
        func testCompletionRate() async throws {
            let session = WorkoutSession(planName: "テスト")

            var exercise1 = CompletedExercise(exerciseId: UUID(), exerciseName: "E1", isCompleted: true)
            exercise1.isCompleted = true

            var exercise2 = CompletedExercise(exerciseId: UUID(), exerciseName: "E2", isCompleted: false)
            exercise2.isCompleted = false

            session.completedExercises = [exercise1, exercise2]

            #expect(session.completionRate == 0.5)
        }
    }

    // MARK: - AIRecommendation Tests

    @Suite("AIRecommendation")
    struct AIRecommendationTests {
        @Test("信頼度テキストが正しい")
        func testConfidenceText() async throws {
            let highConfidence = AIRecommendation(
                planName: "テスト",
                planDescription: "",
                exercises: [],
                category: .general,
                difficulty: .intermediate,
                estimatedDuration: 30,
                confidence: 0.95,
                reasons: []
            )
            #expect(highConfidence.confidenceText == "非常に高い")

            let mediumConfidence = AIRecommendation(
                planName: "テスト",
                planDescription: "",
                exercises: [],
                category: .general,
                difficulty: .intermediate,
                estimatedDuration: 30,
                confidence: 0.65,
                reasons: []
            )
            #expect(mediumConfidence.confidenceText == "中程度")
        }
    }

    // MARK: - Enum Tests

    @Suite("Enums")
    struct EnumTests {
        @Test("FitnessLevel難易度乗数が正しい")
        func testFitnessLevelMultiplier() async throws {
            #expect(FitnessLevel.beginner.difficultyMultiplier == 0.6)
            #expect(FitnessLevel.expert.difficultyMultiplier == 1.2)
        }

        @Test("WeekDay今日が正しく取得できる")
        func testWeekDayToday() async throws {
            let today = WeekDay.today
            let currentWeekday = Calendar.current.component(.weekday, from: Date())
            #expect(today.dayNumber == currentWeekday)
        }

        @Test("MuscleGroupの回復時間が正しい")
        func testMuscleGroupRecoveryTime() async throws {
            #expect(MuscleGroup.glutes.recoveryTime == 72)
            #expect(MuscleGroup.biceps.recoveryTime == 24)
        }
    }
}
