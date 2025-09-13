//
//  AsaWorkoutPlannerTests.swift
//  AsaWorkoutPlannerTests
//
//  AsaWorkoutPlannerの単体テスト
//

import XCTest
import SwiftData
@testable import AsaWorkoutPlanner

@MainActor
final class AsaWorkoutPlannerTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var viewModel: WorkoutPlannerViewModel!
    
    @MainActor
    override func setUpWithError() throws {
        // テスト用のインメモリコンテナを作成
        let schema = Schema([
            WorkoutPlan.self,
            Exercise.self,
            WorkoutSession.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        viewModel = WorkoutPlannerViewModel(modelContext: modelContainer.mainContext)
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        viewModel = nil
    }
    
    // MARK: - WorkoutPlan Tests
    
    func testCreateWorkoutPlan() throws {
        // Given
        let planName = "テストプラン"
        let description = "テスト用のプラン"
        let difficulty = Difficulty.beginner
        let category = WorkoutCategory.general
        
        // When
        viewModel.createWorkoutPlan(
            name: planName,
            description: description,
            difficulty: difficulty,
            category: category
        )
        
        // Then
        XCTAssertEqual(viewModel.workoutPlans.count, 1)
        XCTAssertEqual(viewModel.workoutPlans.first?.name, planName)
        XCTAssertEqual(viewModel.workoutPlans.first?.planDescription, description)
        XCTAssertEqual(viewModel.workoutPlans.first?.difficulty, difficulty)
        XCTAssertEqual(viewModel.workoutPlans.first?.category, category)
    }
    
    func testDuplicatePlan() throws {
        // Given
        let originalPlan = WorkoutPlan(
            name: "オリジナルプラン",
            description: "テスト",
            difficulty: .intermediate,
            category: .strength
        )
        modelContainer.mainContext.insert(originalPlan)
        try modelContainer.mainContext.save()
        viewModel.loadWorkoutPlans()
        
        // When
        viewModel.duplicatePlan(originalPlan)
        
        // Then
        XCTAssertEqual(viewModel.workoutPlans.count, 2)
        XCTAssertTrue(viewModel.workoutPlans.contains { $0.name.contains("コピー") })
    }
    
    // MARK: - Exercise Tests
    
    func testAddExerciseToWorkoutPlan() throws {
        // Given
        let plan = WorkoutPlan(name: "テストプラン")
        let exercise = Exercise(
            name: "プッシュアップ",
            category: .chest,
            sets: 3,
            reps: 10
        )
        
        // When
        plan.addExercise(exercise)
        
        // Then
        XCTAssertEqual(plan.exercises.count, 1)
        XCTAssertEqual(plan.totalExercises, 1)
        XCTAssertEqual(plan.exercises.first?.name, "プッシュアップ")
    }
    
    func testExerciseTotalVolume() throws {
        // Given
        let exercise = Exercise(
            name: "ベンチプレス",
            category: .chest,
            sets: 3,
            reps: 10
        )
        exercise.weight = 60.0
        
        // When
        let totalVolume = exercise.totalVolume
        
        // Then
        XCTAssertEqual(totalVolume, 1800.0) // 60kg × 3sets × 10reps
    }
    
    // MARK: - WorkoutSession Tests
    
    func testStartWorkoutSession() throws {
        // Given
        let plan = WorkoutPlan(name: "テストプラン")
        let exercise = Exercise(name: "スクワット", category: .legs)
        plan.addExercise(exercise)
        modelContainer.mainContext.insert(plan)
        try modelContainer.mainContext.save()
        viewModel.loadWorkoutPlans()
        
        // When
        viewModel.startWorkoutSession(with: plan)
        
        // Then
        XCTAssertNotNil(viewModel.currentSession)
        XCTAssertTrue(viewModel.hasActiveSession)
        XCTAssertEqual(viewModel.currentSession?.workoutPlan?.name, "テストプラン")
    }
    
    func testCompleteWorkoutSession() throws {
        // Given
        let plan = WorkoutPlan(name: "テストプラン")
        modelContainer.mainContext.insert(plan)
        viewModel.startWorkoutSession(with: plan)
        
        // When
        viewModel.completeSession()
        
        // Then
        XCTAssertNil(viewModel.currentSession)
        XCTAssertFalse(viewModel.hasActiveSession)
    }
    
    // MARK: - Statistics Tests
    
    func testWeeklyProgressCalculation() throws {
        // Given
        viewModel.weeklyGoal = 3
        viewModel.weeklyProgress = 2
        
        // When
        let percentage = viewModel.weeklyProgressPercentage
        
        // Then
        XCTAssertEqual(percentage, 2.0/3.0, accuracy: 0.01)
    }
    
    // MARK: - Filter Tests
    
    func testFilterPlansByCategory() throws {
        // Given
        let plan1 = WorkoutPlan(name: "筋トレプラン", category: .strength)
        let plan2 = WorkoutPlan(name: "有酸素プラン", category: .cardio)
        let plan3 = WorkoutPlan(name: "ヨガプラン", category: .yoga)
        
        viewModel.workoutPlans = [plan1, plan2, plan3]
        
        // When
        viewModel.selectedCategory = .strength
        let filtered = viewModel.filteredPlans
        
        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "筋トレプラン")
    }
    
    func testSearchPlans() throws {
        // Given
        let plan1 = WorkoutPlan(name: "朝のワークアウト")
        let plan2 = WorkoutPlan(name: "夜のストレッチ")
        let plan3 = WorkoutPlan(name: "昼のランニング")
        
        viewModel.workoutPlans = [plan1, plan2, plan3]
        
        // When
        viewModel.searchText = "朝"
        let filtered = viewModel.filteredPlans
        
        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "朝のワークアウト")
    }
}