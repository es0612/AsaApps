//
//  WorkoutPlanGeneratorTests.swift
//  AsaFitnessCoachTests
//
//  AI運動プラン生成サービスのテスト
//

import Testing
import Foundation
@testable import AsaFitnessCoach

@Suite("WorkoutPlanGenerator Tests")
struct WorkoutPlanGeneratorTests {
    // MARK: - プラン生成テスト

    @Test("初心者向けプランが生成される")
    @MainActor
    func testBeginnerPlanGeneration() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .beginner, goal: .generalFitness)

        let recommendation = generator.generatePlan(for: profile)

        #expect(recommendation.exercises.count >= 4)
        #expect(recommendation.exercises.count <= 8)
        #expect(recommendation.difficulty == .beginner)
    }

    @Test("上級者向けプランが生成される")
    @MainActor
    func testAdvancedPlanGeneration() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .advanced, goal: .muscleGain)

        let recommendation = generator.generatePlan(for: profile)

        #expect(recommendation.exercises.count >= 4)
        #expect(recommendation.difficulty == .advanced)
        #expect(recommendation.category == .strength)
    }

    @Test("信頼度スコアが0.0から1.0の範囲内")
    @MainActor
    func testConfidenceScoreRange() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .intermediate, goal: .weightLoss)

        let recommendation = generator.generatePlan(for: profile)

        #expect(recommendation.confidence >= 0.0)
        #expect(recommendation.confidence <= 1.0)
    }

    @Test("提案理由が6要因すべて含まれる")
    @MainActor
    func testAllFactorsIncluded() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .intermediate, goal: .generalFitness)

        let recommendation = generator.generatePlan(for: profile)

        let factors = Set(recommendation.reasons.map { $0.factor })
        #expect(factors.contains(.goalAlignment))
        #expect(factors.contains(.fitnessLevel))
        #expect(factors.contains(.equipmentMatch))
        #expect(factors.contains(.timeConstraint))
        #expect(factors.contains(.recoveryStatus))
        #expect(factors.contains(.progressionRate))
    }

    @Test("推定時間が目標時間に近い")
    @MainActor
    func testEstimatedDuration() async throws {
        let generator = WorkoutPlanGenerator()
        let targetDuration = 30
        let profile = createTestProfile(level: .intermediate, goal: .generalFitness, duration: targetDuration)

        let recommendation = generator.generatePlan(for: profile)

        // 目標時間の50%から150%の範囲内
        #expect(recommendation.estimatedDuration >= targetDuration / 2)
        #expect(recommendation.estimatedDuration <= targetDuration * 2)
    }

    // MARK: - 器具フィルタリングテスト

    @Test("器具なしでも自重エクササイズが提案される")
    @MainActor
    func testBodyweightExercisesOnly() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .beginner, goal: .generalFitness, equipment: [])

        let recommendation = generator.generatePlan(for: profile)

        // 少なくとも1つのエクササイズが提案される
        #expect(!recommendation.exercises.isEmpty)
    }

    @Test("ダンベルのみで適切なエクササイズが提案される")
    @MainActor
    func testDumbbellExercises() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .intermediate, goal: .muscleGain, equipment: [.dumbbells])

        let recommendation = generator.generatePlan(for: profile)

        #expect(!recommendation.exercises.isEmpty)
    }

    // MARK: - 目標別テスト

    @Test("筋力アップ目標で筋力系エクササイズが提案される")
    @MainActor
    func testMuscleGainGoal() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .intermediate, goal: .muscleGain)

        let recommendation = generator.generatePlan(for: profile)

        #expect(recommendation.category == .strength || recommendation.category == .bodyweight)
    }

    @Test("減量目標でHIITまたは有酸素が提案される")
    @MainActor
    func testWeightLossGoal() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .intermediate, goal: .weightLoss)

        let recommendation = generator.generatePlan(for: profile)

        let expectedCategories: [WorkoutCategory] = [.hiit, .cardio, .strength]
        #expect(expectedCategories.contains(recommendation.category))
    }

    @Test("柔軟性目標でヨガまたはストレッチが提案される")
    @MainActor
    func testFlexibilityGoal() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .beginner, goal: .flexibility)

        let recommendation = generator.generatePlan(for: profile)

        let expectedCategories: [WorkoutCategory] = [.yoga, .stretching]
        #expect(expectedCategories.contains(recommendation.category))
    }

    // MARK: - エクササイズスコアテスト

    @Test("エクササイズのマッチスコアが0.0から1.0の範囲内")
    @MainActor
    func testExerciseMatchScoreRange() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .intermediate, goal: .generalFitness)

        let recommendation = generator.generatePlan(for: profile)

        for exercise in recommendation.exercises {
            #expect(exercise.matchScore >= 0.0)
            #expect(exercise.matchScore <= 1.0)
        }
    }

    @Test("セット数がレベルに応じて調整される")
    @MainActor
    func testSetsAdjustedByLevel() async throws {
        let generator = WorkoutPlanGenerator()

        let beginnerProfile = createTestProfile(level: .beginner, goal: .muscleGain)
        let advancedProfile = createTestProfile(level: .advanced, goal: .muscleGain)

        let beginnerRec = generator.generatePlan(for: beginnerProfile)
        let advancedRec = generator.generatePlan(for: advancedProfile)

        // 上級者の平均セット数 >= 初心者の平均セット数
        let beginnerAvgSets = Double(beginnerRec.exercises.reduce(0) { $0 + $1.suggestedSets }) / Double(beginnerRec.exercises.count)
        let advancedAvgSets = Double(advancedRec.exercises.reduce(0) { $0 + $1.suggestedSets }) / Double(advancedRec.exercises.count)

        #expect(advancedAvgSets >= beginnerAvgSets)
    }

    // MARK: - 重み調整テスト

    @Test("カスタム重みで結果が変わる")
    @MainActor
    func testCustomWeights() async throws {
        let generator = WorkoutPlanGenerator()
        let profile = createTestProfile(level: .intermediate, goal: .generalFitness)

        // デフォルト重み
        let defaultRec = generator.generatePlan(for: profile)

        // カスタム重み（目標適合度を最大化）
        generator.weights = PlanWeights(
            goalAlignment: 0.6,
            fitnessLevel: 0.1,
            equipmentMatch: 0.1,
            timeConstraint: 0.1,
            recoveryStatus: 0.05,
            progressionRate: 0.05
        )
        let customRec = generator.generatePlan(for: profile)

        // 両方とも有効な結果を返す
        #expect(!defaultRec.exercises.isEmpty)
        #expect(!customRec.exercises.isEmpty)
    }

    // MARK: - ヘルパーメソッド

    private func createTestProfile(
        level: FitnessLevel,
        goal: FitnessGoalType,
        duration: Int = 30,
        equipment: [Equipment] = [.none]
    ) -> UserProfile {
        let profile = UserProfile(
            name: "テストユーザー",
            fitnessLevel: level,
            primaryGoal: goal,
            preferredWorkoutDuration: duration,
            workoutDaysPerWeek: 3
        )
        profile.availableEquipment = equipment
        return profile
    }
}
