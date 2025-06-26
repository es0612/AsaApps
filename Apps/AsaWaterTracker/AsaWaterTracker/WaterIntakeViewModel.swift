
import Foundation
import Combine

class WaterIntakeViewModel: ObservableObject {
    @Published var todayIntake: Double = 0.0
    @Published var history: [WaterLog] = []
    @Published var goal: Double = 2000.0 // Default goal

    private let historyKey = "waterIntakeHistory"
    private let goalKey = "waterIntakeGoal"

    init() {
        loadGoal()
        loadHistory()
        updateTodayIntake()
    }

    var progress: Double {
        guard goal > 0 else { return 0 }
        return todayIntake / goal
    }

    func addIntake(amount: Double) {
        guard amount > 0 else { return }
        let log = WaterLog(date: Date(), amount: amount)
        history.append(log)
        saveHistory()
        updateTodayIntake()
    }

    func updateGoal(newGoal: Double) {
        guard newGoal > 0 else { return }
        goal = newGoal
        saveGoal()
    }

    func resetTodayIntake() {
        history.removeAll { Calendar.current.isDateInToday($0.date) }
        saveHistory()
        updateTodayIntake()
    }

    private func updateTodayIntake() {
        todayIntake = history
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([WaterLog].self, from: data) {
            history = decoded
        }
    }

    private func saveGoal() {
        UserDefaults.standard.set(goal, forKey: goalKey)
    }

    private func loadGoal() {
        let savedGoal = UserDefaults.standard.double(forKey: goalKey)
        if savedGoal > 0 {
            goal = savedGoal
        }
    }
}
