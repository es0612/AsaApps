import SwiftUI
import Charts
import AsaUIKit

struct ChartsView: View {
    let viewModel: HabitViewModel
    @State private var selectedTimeRange = TimeRange.week
    @State private var selectedHabit: Habit?

    enum TimeRange: String, CaseIterable {
        case week = "週"
        case month = "月"
        case year = "年"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 時間範囲選択
                    timeRangeSelector

                    // 習慣選択
                    habitSelector

                    // 達成率グラフ
                    if let habit = selectedHabit {
                        progressLineChart(for: habit)
                    } else {
                        overallProgressChart
                    }

                    // カテゴリ別円グラフ
                    categoryPieChart

                    // 週間パフォーマンス
                    weeklyPerformanceChart
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationTitle("グラフ")
            .onAppear {
                if selectedHabit == nil {
                    selectedHabit = viewModel.habits.first
                }
            }
        }
    }

    // MARK: - Subviews

    private var timeRangeSelector: some View {
        Picker("期間", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue)
                    .tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var habitSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全体選択
                HabitChip(
                    name: "全体",
                    icon: "chart.bar.fill",
                    color: AsaColors.coffeeBrown,
                    isSelected: selectedHabit == nil
                ) {
                    withAnimation {
                        selectedHabit = nil
                    }
                }

                // 各習慣
                ForEach(viewModel.habits) { habit in
                    HabitChip(
                        name: habit.name,
                        icon: habit.icon,
                        color: Color(habit.color),
                        isSelected: selectedHabit?.id == habit.id
                    ) {
                        withAnimation {
                            selectedHabit = habit
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func progressLineChart(for habit: Habit) -> some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(habit.name)の進捗")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Chart {
                    ForEach(generateProgressData(for: habit)) { data in
                        LineMark(
                            x: .value("日付", data.date),
                            y: .value("完了", data.completed ? 1 : 0)
                        )
                        .foregroundStyle(Color(habit.color).gradient)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                        PointMark(
                            x: .value("日付", data.date),
                            y: .value("完了", data.completed ? 1 : 0)
                        )
                        .foregroundStyle(Color(habit.color))
                        .symbolSize(data.completed ? 120 : 60)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(values: [0, 1]) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(intValue == 1 ? "完了" : "未完了")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, selectedTimeRange.days / 7))) { value in
                        AxisValueLabel(format: .dateTime.month().day())
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
    }

    private var overallProgressChart: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("全体の達成率")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Chart {
                    ForEach(generateOverallProgressData()) { data in
                        BarMark(
                            x: .value("日付", data.date),
                            y: .value("達成率", data.completionRate)
                        )
                        .foregroundStyle(AsaColors.coffeeBrown.gradient)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var categoryPieChart: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("カテゴリ別習慣数")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                let categoryData = generateCategoryData()

                Chart(categoryData) { data in
                    SectorMark(
                        angle: .value("習慣数", data.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("カテゴリ", data.category))
                    .cornerRadius(4)
                }
                .frame(height: 250)
                .chartLegend(position: .bottom, alignment: .center, spacing: 12)
                .chartBackground { proxy in
                    GeometryReader { geometry in
                        let frame = geometry.frame(in: .local)
                        VStack {
                            Text("\(viewModel.totalActiveHabits)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(AsaColors.darkSlate)
                            Text("習慣")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .padding()
        }
    }

    private var weeklyPerformanceChart: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("曜日別パフォーマンス")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Chart(generateWeeklyData()) { data in
                    BarMark(
                        x: .value("曜日", data.weekday),
                        y: .value("完了数", data.completions)
                    )
                    .foregroundStyle(AsaColors.mocha.gradient)
                    .cornerRadius(8)
                }
                .frame(height: 200)
            }
            .padding()
        }
    }

    // MARK: - Data Generation

    private func generateProgressData(for habit: Habit) -> [ProgressData] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate

        var data: [ProgressData] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let isCompleted = habit.records.contains { record in
                calendar.isDate(record.completedAt, inSameDayAs: currentDate)
            }
            data.append(ProgressData(date: currentDate, completed: isCompleted))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return data
    }

    private func generateOverallProgressData() -> [OverallProgressData] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: endDate) ?? endDate

        var data: [OverallProgressData] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let totalHabits = viewModel.habits.count
            let completedHabits = viewModel.habits.filter { habit in
                habit.records.contains { record in
                    calendar.isDate(record.completedAt, inSameDayAs: currentDate)
                }
            }.count

            let rate = totalHabits > 0 ? Double(completedHabits) / Double(totalHabits) * 100 : 0
            data.append(OverallProgressData(date: currentDate, completionRate: rate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return data
    }

    private func generateCategoryData() -> [CategoryData] {
        var categoryCount: [HabitCategory: Int] = [:]

        for habit in viewModel.habits where habit.isActive {
            categoryCount[habit.category, default: 0] += 1
        }

        return categoryCount.map { CategoryData(category: $0.key.rawValue, count: $0.value) }
    }

    private func generateWeeklyData() -> [WeeklyData] {
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        var weekdayCompletions: [String: Int] = [:]

        let calendar = Calendar.current
        for habit in viewModel.habits {
            for record in habit.records {
                let weekday = calendar.component(.weekday, from: record.completedAt) - 1
                let weekdayName = weekdays[weekday]
                weekdayCompletions[weekdayName, default: 0] += 1
            }
        }

        return weekdays.map { WeeklyData(weekday: $0, completions: weekdayCompletions[$0] ?? 0) }
    }
}

// MARK: - Supporting Types

struct ProgressData: Identifiable {
    let id = UUID()
    let date: Date
    let completed: Bool
}

struct OverallProgressData: Identifiable {
    let id = UUID()
    let date: Date
    let completionRate: Double
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

struct WeeklyData: Identifiable {
    let id = UUID()
    let weekday: String
    let completions: Int
}

struct HabitChip: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : AsaColors.softCream)
            .foregroundColor(isSelected ? .white : AsaColors.darkSlate)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}