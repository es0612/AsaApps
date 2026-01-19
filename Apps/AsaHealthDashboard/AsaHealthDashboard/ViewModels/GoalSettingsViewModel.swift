//
//  GoalSettingsViewModel.swift
//  AsaHealthDashboard
//
//  目標設定用ViewModel
//

import Foundation

@MainActor
@Observable
final class GoalSettingsViewModel {
    // MARK: - State

    var stepsGoal: Double = HealthCategory.steps.defaultGoal
    var distanceGoal: Double = HealthCategory.distance.defaultGoal
    var caloriesGoal: Double = HealthCategory.calories.defaultGoal
    var exerciseTimeGoal: Double = HealthCategory.exerciseTime.defaultGoal
    var sleepGoal: Double = HealthCategory.sleep.defaultGoal

    var hasUnsavedChanges = false

    // MARK: - 親ViewModelへの参照

    private weak var dashboardViewModel: HealthDashboardViewModel?

    // MARK: - Init

    init(dashboardViewModel: HealthDashboardViewModel) {
        self.dashboardViewModel = dashboardViewModel
        loadCurrentGoals()
    }

    // MARK: - 目標値の読み込み

    func loadCurrentGoals() {
        guard let viewModel = dashboardViewModel else { return }

        stepsGoal = viewModel.goalValue(for: .steps)
        distanceGoal = viewModel.goalValue(for: .distance)
        caloriesGoal = viewModel.goalValue(for: .calories)
        exerciseTimeGoal = viewModel.goalValue(for: .exerciseTime)
        sleepGoal = viewModel.goalValue(for: .sleep)

        hasUnsavedChanges = false
    }

    // MARK: - 目標値の更新

    func updateGoal(for category: HealthCategory, value: Double) {
        switch category {
        case .steps:
            stepsGoal = value
        case .distance:
            distanceGoal = value
        case .calories:
            caloriesGoal = value
        case .exerciseTime:
            exerciseTimeGoal = value
        case .sleep:
            sleepGoal = value
        }
        hasUnsavedChanges = true
    }

    func goalValue(for category: HealthCategory) -> Double {
        switch category {
        case .steps: return stepsGoal
        case .distance: return distanceGoal
        case .calories: return caloriesGoal
        case .exerciseTime: return exerciseTimeGoal
        case .sleep: return sleepGoal
        }
    }

    // MARK: - 保存

    func saveAllGoals() {
        guard let viewModel = dashboardViewModel else { return }

        viewModel.updateGoal(for: .steps, value: stepsGoal)
        viewModel.updateGoal(for: .distance, value: distanceGoal)
        viewModel.updateGoal(for: .calories, value: caloriesGoal)
        viewModel.updateGoal(for: .exerciseTime, value: exerciseTimeGoal)
        viewModel.updateGoal(for: .sleep, value: sleepGoal)

        hasUnsavedChanges = false

        // データを再読み込み
        Task {
            await viewModel.refreshAllData()
        }
    }

    // MARK: - リセット

    func resetToDefaults() {
        stepsGoal = HealthCategory.steps.defaultGoal
        distanceGoal = HealthCategory.distance.defaultGoal
        caloriesGoal = HealthCategory.calories.defaultGoal
        exerciseTimeGoal = HealthCategory.exerciseTime.defaultGoal
        sleepGoal = HealthCategory.sleep.defaultGoal

        hasUnsavedChanges = true
    }
}
