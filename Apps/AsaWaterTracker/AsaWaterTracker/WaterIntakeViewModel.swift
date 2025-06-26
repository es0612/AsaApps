
import Foundation
import Combine

class WaterIntakeViewModel: ObservableObject {
    @Published var todayIntake: Double = 0.0
    @Published var history: [WaterLog] = []
    
    let goal: Double = 2000.0 // 2L goal
    private let userDefaultsKey = "waterIntakeHistory"
    
    init() {
        loadHistory()
        updateTodayIntake()
    }
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return todayIntake / goal
    }
    
    func addIntake(amount: Double) {
        let log = WaterLog(date: Date(), amount: amount)
        history.append(log)
        saveHistory()
        updateTodayIntake()
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
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([WaterLog].self, from: data) {
            history = decoded
        }
    }
}
