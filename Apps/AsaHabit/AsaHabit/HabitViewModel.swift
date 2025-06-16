import Observation
import Foundation

@Observable
class HabitViewModel {
    var habits: [Habit] = []
    var habitName: String = ""
    var nameError: String? = nil
    
    func validateHabitName() {
        let trimmed = habitName.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            nameError = "習慣名を入力してください"
            habitName = ""
        } else {
            nameError = nil
            habitName = trimmed
        }
    }
    
    func addHabit() {
        guard !habitName.trimmingCharacters(in: .whitespaces).isEmpty else {
            nameError = "習慣名を入力してください"
            return
        }
        let newHabit = Habit(name: habitName, isChecked: false, date: Date())
        habits.append(newHabit)
        saveToUserDefaults()
        habitName = ""
        nameError = nil
    }
    
    func toggleCheck(for habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].isChecked.toggle()
            saveToUserDefaults()
        }
    }
    
    func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: "habits")
        }
    }
    
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "habits"),
           let savedHabits = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = savedHabits
        }
    }
}
