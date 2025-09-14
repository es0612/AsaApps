import Foundation
import SwiftData
import SwiftUI

@Observable
final class HabitViewModel {
    // MARK: - Properties

    private var modelContext: ModelContext?
    var habits: [Habit] = []
    var todayHabits: [Habit] = []
    var selectedHabit: Habit?
    var isLoading = false
    var errorMessage: String?
    var searchText = ""

    // フィルタリング用
    var selectedCategory: HabitCategory?
    var showOnlyActive = true

    // MARK: - Computed Properties

    var filteredHabits: [Habit] {
        var filtered = habits

        // アクティブフィルター
        if showOnlyActive {
            filtered = filtered.filter { $0.isActive }
        }

        // カテゴリフィルター
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // 検索フィルター
        if !searchText.isEmpty {
            filtered = filtered.filter { habit in
                habit.name.localizedCaseInsensitiveContains(searchText) ||
                habit.habitDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    var todayProgress: Double {
        guard !todayHabits.isEmpty else { return 0 }
        let completed = todayHabits.filter { $0.isCompletedToday }.count
        return Double(completed) / Double(todayHabits.count)
    }

    var totalActiveHabits: Int {
        habits.filter { $0.isActive }.count
    }

    var totalCompletedToday: Int {
        todayHabits.filter { $0.isCompletedToday }.count
    }

    // MARK: - Initialization

    init() {
        setupTodayHabits()
    }

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await loadHabits()
        }
    }

    // MARK: - Data Loading

    @MainActor
    func loadHabits() async {
        guard let modelContext = modelContext else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            habits = try modelContext.fetch(descriptor)
            setupTodayHabits()
        } catch {
            errorMessage = "習慣の読み込みに失敗しました: \(error.localizedDescription)"
        }
    }

    private func setupTodayHabits() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let isWeekend = weekday == 1 || weekday == 7

        todayHabits = habits.filter { habit in
            guard habit.isActive else { return false }

            switch habit.targetFrequency {
            case .daily:
                return true
            case .weekdays:
                return !isWeekend
            case .weekends:
                return isWeekend
            case .weekly3, .weekly5, .custom:
                // 簡易実装: 週3回と週5回は曜日で判定
                if habit.targetFrequency == .weekly3 {
                    return [2, 4, 6].contains(weekday) // 月水金
                } else if habit.targetFrequency == .weekly5 {
                    return !isWeekend
                }
                return true
            }
        }
    }

    // MARK: - Habit Management

    @MainActor
    func addHabit(
        name: String,
        description: String,
        category: HabitCategory,
        icon: String,
        color: String,
        frequency: TargetFrequency,
        reminderTime: Date?
    ) async {
        guard let modelContext = modelContext else { return }

        let habit = Habit(
            name: name,
            habitDescription: description,
            category: category,
            icon: icon,
            color: color,
            targetFrequency: frequency,
            reminderTime: reminderTime
        )

        modelContext.insert(habit)

        do {
            try modelContext.save()
            await loadHabits()
        } catch {
            errorMessage = "習慣の追加に失敗しました: \(error.localizedDescription)"
        }
    }

    @MainActor
    func updateHabit(_ habit: Habit) async {
        guard let modelContext = modelContext else { return }

        habit.modifiedAt = Date()

        do {
            try modelContext.save()
            await loadHabits()
        } catch {
            errorMessage = "習慣の更新に失敗しました: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteHabit(_ habit: Habit) async {
        guard let modelContext = modelContext else { return }

        modelContext.delete(habit)

        do {
            try modelContext.save()
            await loadHabits()
        } catch {
            errorMessage = "習慣の削除に失敗しました: \(error.localizedDescription)"
        }
    }

    @MainActor
    func toggleHabitActive(_ habit: Habit) async {
        habit.isActive.toggle()
        habit.modifiedAt = Date()
        await updateHabit(habit)
    }

    // MARK: - Record Management

    @MainActor
    func recordCompletion(for habit: Habit, note: String = "", duration: TimeInterval? = nil, mood: RecordMood? = nil) async {
        guard let modelContext = modelContext else { return }

        // 今日の記録があるか確認
        let calendar = Calendar.current
        let existingRecord = habit.records.first { record in
            calendar.isDateInToday(record.completedAt)
        }

        if existingRecord != nil {
            // 既に記録がある場合は更新
            existingRecord?.note = note
            existingRecord?.duration = duration
            existingRecord?.mood = mood
        } else {
            // 新規記録を作成
            let record = HabitRecord(
                habit: habit,
                note: note,
                duration: duration,
                mood: mood
            )
            modelContext.insert(record)
            habit.totalCompletions += 1
        }

        // ストリークを更新
        habit.updateStreak()
        habit.modifiedAt = Date()

        do {
            try modelContext.save()
            await loadHabits()
        } catch {
            errorMessage = "記録の保存に失敗しました: \(error.localizedDescription)"
        }
    }

    @MainActor
    func removeCompletion(for habit: Habit) async {
        guard let modelContext = modelContext else { return }

        // 今日の記録を探す
        let calendar = Calendar.current
        if let todayRecord = habit.records.first(where: { calendar.isDateInToday($0.completedAt) }) {
            modelContext.delete(todayRecord)
            habit.totalCompletions = max(0, habit.totalCompletions - 1)
            habit.updateStreak()
            habit.modifiedAt = Date()

            do {
                try modelContext.save()
                await loadHabits()
            } catch {
                errorMessage = "記録の削除に失敗しました: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Sample Data

    @MainActor
    func createSampleData() async {
        guard let modelContext = modelContext else { return }

        let sampleHabits = [
            ("朝のジョギング", "毎朝30分のジョギング", HabitCategory.exercise, "figure.run", "AsaCoffeeBrown", TargetFrequency.daily),
            ("読書", "就寝前に30分読書", HabitCategory.learning, "book.fill", "AsaMocha", TargetFrequency.daily),
            ("瞑想", "10分間の瞑想", HabitCategory.mindfulness, "brain.head.profile", "AsaSoftCream", TargetFrequency.daily),
            ("英語学習", "Duolingoで英語学習", HabitCategory.learning, "globe", "AsaDarkSlate", TargetFrequency.weekdays),
            ("水分補給", "2リットルの水を飲む", HabitCategory.health, "drop.fill", "AsaSoftCream", TargetFrequency.daily),
            ("日記", "一日の振り返り", HabitCategory.lifestyle, "pencil.and.scribble", "AsaMutedSage", TargetFrequency.daily)
        ]

        for (name, desc, category, icon, color, frequency) in sampleHabits {
            let habit = Habit(
                name: name,
                habitDescription: desc,
                category: category,
                icon: icon,
                color: color,
                targetFrequency: frequency
            )

            // ランダムな過去の記録を追加
            let calendar = Calendar.current
            for i in 0..<30 {
                if Bool.random() {
                    if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                        let record = HabitRecord(
                            habit: habit,
                            completedAt: date,
                            mood: RecordMood.allCases.randomElement()
                        )
                        modelContext.insert(record)
                        habit.totalCompletions += 1
                    }
                }
            }

            habit.updateStreak()
            modelContext.insert(habit)
        }

        do {
            try modelContext.save()
            await loadHabits()
        } catch {
            errorMessage = "サンプルデータの作成に失敗しました: \(error.localizedDescription)"
        }
    }
}