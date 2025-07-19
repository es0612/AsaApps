//
//  AsaFitnessGoalTests.swift
//  AsaFitnessGoalTests
//  
//  Created on 2025/07/19
//

import Testing
import Foundation
import SwiftData
@testable import AsaFitnessGoal

struct AsaFitnessGoalTests {
    
    @Test("FitnessGoalモデルの初期化テスト")
    func fitnessGoalInitialization() throws {
        let title = "毎日10,000歩"
        let category = GoalCategory.steps
        let targetValue: Double = 10000
        let period = GoalPeriod.daily
        
        let goal = FitnessGoal(
            title: title,
            category: category,
            targetValue: targetValue,
            period: period
        )
        
        #expect(goal.title == title)
        #expect(goal.category == category)
        #expect(goal.targetValue == targetValue)
        #expect(goal.period == period)
        #expect(goal.isActive == true)
        #expect(goal.id != UUID())
        #expect(goal.createdAt <= Date())
        #expect(goal.updatedAt <= Date())
    }
    
    @Test("WorkoutRecordモデルの初期化テスト")
    func workoutRecordInitialization() throws {
        let goalId = UUID()
        let category = GoalCategory.steps
        let value: Double = 5000
        let note = "朝の散歩"
        
        let record = WorkoutRecord(
            goalId: goalId,
            category: category,
            value: value,
            note: note,
            isManualEntry: true
        )
        
        #expect(record.goalId == goalId)
        #expect(record.category == category)
        #expect(record.value == value)
        #expect(record.note == note)
        #expect(record.isManualEntry == true)
        #expect(record.id != UUID())
        #expect(record.recordedAt <= Date())
    }
    
    @Test("GoalCategoryの表示名とアイコンテスト")
    func goalCategoryProperties() throws {
        let stepsCategory = GoalCategory.steps
        #expect(stepsCategory.displayName == "歩数")
        #expect(stepsCategory.unit == "歩")
        #expect(stepsCategory.icon == "figure.walk")
        
        let distanceCategory = GoalCategory.distance
        #expect(distanceCategory.displayName == "距離")
        #expect(distanceCategory.unit == "km")
        #expect(distanceCategory.icon == "location")
        
        let activeTimeCategory = GoalCategory.activeTime
        #expect(activeTimeCategory.displayName == "運動時間")
        #expect(activeTimeCategory.unit == "分")
        #expect(activeTimeCategory.icon == "timer")
        
        let caloriesCategory = GoalCategory.calories
        #expect(caloriesCategory.displayName == "消費カロリー")
        #expect(caloriesCategory.unit == "kcal")
        #expect(caloriesCategory.icon == "flame")
        
        let workoutsCategory = GoalCategory.workouts
        #expect(workoutsCategory.displayName == "ワークアウト回数")
        #expect(workoutsCategory.unit == "回")
        #expect(workoutsCategory.icon == "dumbbell")
    }
    
    @Test("GoalPeriodの表示名テスト")
    func goalPeriodDisplayNames() throws {
        #expect(GoalPeriod.daily.displayName == "1日")
        #expect(GoalPeriod.weekly.displayName == "1週間")
        #expect(GoalPeriod.monthly.displayName == "1ヶ月")
    }
    
    @Test("期間計算テスト")
    func periodCalculation() throws {
        let dailyGoal = FitnessGoal(
            title: "日次目標",
            category: .steps,
            targetValue: 10000,
            period: .daily
        )
        
        let calendar = Calendar.current
        let now = Date()
        let expectedStart = calendar.startOfDay(for: now)
        let expectedEnd = calendar.date(byAdding: .day, value: 1, to: expectedStart)!
        
        #expect(calendar.isDate(dailyGoal.currentPeriodStart, inSameDayAs: expectedStart))
        #expect(calendar.isDate(dailyGoal.currentPeriodEnd, inSameDayAs: expectedEnd))
    }
    
    @Test("WorkoutRecordのフォーマット表示テスト")
    func workoutRecordFormatting() throws {
        let stepsRecord = WorkoutRecord(
            goalId: UUID(),
            category: .steps,
            value: 12345,
            isManualEntry: true
        )
        #expect(stepsRecord.formattedValue == "12345")
        
        let distanceRecord = WorkoutRecord(
            goalId: UUID(),
            category: .distance,
            value: 5.75,
            isManualEntry: true
        )
        #expect(distanceRecord.formattedValue == "5.8")
        
        let caloriesRecord = WorkoutRecord(
            goalId: UUID(),
            category: .calories,
            value: 250.6,
            isManualEntry: true
        )
        #expect(caloriesRecord.formattedValue == "251")
    }
}

struct FitnessViewModelTests {
    
    @Test("FitnessViewModelの初期化テスト")
    func fitnessViewModelInitialization() throws {
        let viewModel = FitnessViewModel()
        
        #expect(viewModel.goals.isEmpty)
        #expect(viewModel.workoutRecords.isEmpty)
        #expect(viewModel.selectedGoal == nil)
        #expect(viewModel.isShowingAddGoalSheet == false)
        #expect(viewModel.isShowingAddRecordSheet == false)
        #expect(viewModel.isShowingEditGoalSheet == false)
        #expect(viewModel.currentProgress.isEmpty)
        #expect(viewModel.isLoadingProgress == false)
    }
    
    @Test("UI制御メソッドテスト")
    func uiControlMethods() throws {
        let viewModel = FitnessViewModel()
        let testGoal = FitnessGoal(
            title: "テスト目標",
            category: .steps,
            targetValue: 10000,
            period: .daily
        )
        
        // Add Goal Sheet
        viewModel.showAddGoalSheet()
        #expect(viewModel.isShowingAddGoalSheet == true)
        
        viewModel.hideAddGoalSheet()
        #expect(viewModel.isShowingAddGoalSheet == false)
        
        // Add Record Sheet
        viewModel.showAddRecordSheet()
        #expect(viewModel.isShowingAddRecordSheet == true)
        
        viewModel.hideAddRecordSheet()
        #expect(viewModel.isShowingAddRecordSheet == false)
        
        // Edit Goal Sheet
        viewModel.showEditGoalSheet(for: testGoal)
        #expect(viewModel.isShowingEditGoalSheet == true)
        #expect(viewModel.selectedGoal?.id == testGoal.id)
        
        viewModel.hideEditGoalSheet()
        #expect(viewModel.isShowingEditGoalSheet == false)
        #expect(viewModel.selectedGoal == nil)
    }
    
    @Test("進捗計算ロジックテスト")
    func progressCalculation() throws {
        let viewModel = FitnessViewModel()
        let goal = FitnessGoal(
            title: "歩数目標",
            category: .steps,
            targetValue: 10000,
            period: .daily
        )
        
        // 進捗データを設定
        viewModel.currentProgress[.steps] = 5000
        
        let progress = viewModel.getProgress(for: goal)
        #expect(progress == 0.5) // 50%の進捗
        
        let progressText = viewModel.getProgressText(for: goal)
        #expect(progressText.contains("5000"))
        #expect(progressText.contains("10000"))
        #expect(progressText.contains("歩"))
    }
}

struct HealthKitServiceTests {
    
    @Test("HealthKitServiceの初期化テスト")
    func healthKitServiceInitialization() throws {
        let service = HealthKitService()
        
        // HealthKitの可用性はデバイスに依存するため、初期化のみテスト
        #expect(service.authorizationStatus == .notDetermined)
    }
}
