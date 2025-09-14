import SwiftUI
import AsaUIKit

struct StatisticsView: View {
    let viewModel: HabitViewModel
    @State private var selectedPeriod = Period.allTime

    enum Period: String, CaseIterable {
        case today = "今日"
        case week = "今週"
        case month = "今月"
        case allTime = "全期間"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択
                    periodSelector

                    // 総合統計
                    overallStatistics

                    // トップパフォーマー
                    topPerformers

                    // カテゴリ別統計
                    categoryStatistics

                    // 達成カレンダー
                    achievementCalendar
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationTitle("統計")
        }
    }

    // MARK: - Subviews

    private var periodSelector: some View {
        Picker("期間", selection: $selectedPeriod) {
            ForEach(Period.allCases, id: \.self) { period in
                Text(period.rawValue)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var overallStatistics: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatisticTile(
                    title: "総習慣数",
                    value: "\(viewModel.totalActiveHabits)",
                    icon: "list.bullet",
                    color: AsaColors.coffeeBrown
                )

                StatisticTile(
                    title: "今日の達成率",
                    value: "\(Int(viewModel.todayProgress * 100))%",
                    icon: "checkmark.circle.fill",
                    color: AsaColors.mocha
                )
            }

            HStack(spacing: 12) {
                StatisticTile(
                    title: "総完了回数",
                    value: "\(calculateTotalCompletions())",
                    icon: "star.fill",
                    color: AsaColors.mutedSage
                )

                StatisticTile(
                    title: "平均達成率",
                    value: "\(calculateAverageCompletionRate())%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: AsaColors.darkSlate
                )
            }
        }
    }

    private var topPerformers: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("トップパフォーマー")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(getTopHabits()) { habit in
                    TopPerformerRow(habit: habit)
                }
            }
        }
    }

    private var categoryStatistics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ別パフォーマンス")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(getCategoryStatistics(), id: \.category) { stat in
                    CategoryStatRow(stat: stat)
                }
            }
        }
    }

    private var achievementCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("達成カレンダー")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
                .padding(.horizontal, 4)

            AsaCard {
                CalendarHeatMap(habits: viewModel.habits)
                    .padding()
            }
        }
    }

    // MARK: - Data Calculation

    private func calculateTotalCompletions() -> Int {
        viewModel.habits.reduce(0) { $0 + $1.totalCompletions }
    }

    private func calculateAverageCompletionRate() -> Int {
        guard !viewModel.habits.isEmpty else { return 0 }
        let totalRate = viewModel.habits.reduce(0.0) { $0 + $1.completionRate }
        return Int(totalRate / Double(viewModel.habits.count))
    }

    private func getTopHabits() -> [Habit] {
        Array(viewModel.habits.sorted { $0.currentStreak > $1.currentStreak }.prefix(3))
    }

    private func getCategoryStatistics() -> [CategoryStat] {
        var stats: [HabitCategory: (count: Int, completions: Int)] = [:]

        for habit in viewModel.habits where habit.isActive {
            var current = stats[habit.category] ?? (count: 0, completions: 0)
            current.count += 1
            current.completions += habit.totalCompletions
            stats[habit.category] = current
        }

        return stats.map { CategoryStat(category: $0.key, habitCount: $0.value.count, totalCompletions: $0.value.completions) }
            .sorted { $0.totalCompletions > $1.totalCompletions }
    }
}

// MARK: - Supporting Views

struct StatisticTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        AsaCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AsaColors.darkSlate)

                    Text(title)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
}

struct TopPerformerRow: View {
    let habit: Habit

    var body: some View {
        AsaCard {
            HStack(spacing: 16) {
                Image(systemName: habit.icon)
                    .font(.title2)
                    .foregroundColor(Color(habit.color))
                    .frame(width: 40, height: 40)
                    .background(Color(habit.color).opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AsaColors.darkSlate)

                    Text(habit.category.rawValue)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(habit.currentStreak)")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Text("\(habit.totalCompletions)回完了")
                        .font(.caption2)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .padding()
        }
    }
}

struct CategoryStat {
    let category: HabitCategory
    let habitCount: Int
    let totalCompletions: Int
}

struct CategoryStatRow: View {
    let stat: CategoryStat

    var body: some View {
        AsaCard {
            HStack(spacing: 16) {
                Image(systemName: stat.category.icon)
                    .font(.title2)
                    .foregroundColor(Color(stat.category.defaultColor))
                    .frame(width: 40, height: 40)
                    .background(Color(stat.category.defaultColor).opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AsaColors.darkSlate)

                    Text("\(stat.habitCount)個の習慣")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                Spacer()

                Text("\(stat.totalCompletions)回")
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
            }
            .padding()
        }
    }
}

// MARK: - Calendar Heat Map

struct CalendarHeatMap: View {
    let habits: [Habit]
    @State private var selectedDate = Date()

    var body: some View {
        VStack(spacing: 8) {
            // 月表示
            HStack {
                Button {
                    withAnimation {
                        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AsaColors.coffeeBrown)
                }

                Spacer()

                Text(selectedDate, format: .dateTime.year().month(.wide))
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Button {
                    withAnimation {
                        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }

            // カレンダーグリッド
            CalendarGrid(month: selectedDate, habits: habits)
        }
    }
}

struct CalendarGrid: View {
    let month: Date
    let habits: [Habit]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(spacing: 8) {
            // 曜日ヘッダー
            HStack(spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日付グリッド
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, completionRate: getCompletionRate(for: date))
                    } else {
                        Color.clear
                            .frame(height: 30)
                    }
                }
            }
        }
    }

    private func getDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        // 最後の週を埋める
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func getCompletionRate(for date: Date) -> Double {
        let calendar = Calendar.current
        let applicableHabits = habits.filter { habit in
            calendar.date(from: calendar.dateComponents([.year, .month, .day], from: habit.createdAt))! <= date
        }

        guard !applicableHabits.isEmpty else { return 0 }

        let completedCount = applicableHabits.filter { habit in
            habit.records.contains { record in
                calendar.isDate(record.completedAt, inSameDayAs: date)
            }
        }.count

        return Double(completedCount) / Double(applicableHabits.count)
    }
}

struct DayCell: View {
    let date: Date
    let completionRate: Double

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var backgroundColor: Color {
        if completionRate == 0 {
            return AsaColors.softCream.opacity(0.3)
        } else if completionRate < 0.5 {
            return AsaColors.mocha.opacity(0.3)
        } else if completionRate < 1.0 {
            return AsaColors.coffeeBrown.opacity(0.5)
        } else {
            return AsaColors.coffeeBrown
        }
    }

    var body: some View {
        Text(dayNumber)
            .font(.caption2)
            .foregroundColor(completionRate == 1.0 ? .white : AsaColors.darkSlate)
            .frame(width: 30, height: 30)
            .background(backgroundColor)
            .cornerRadius(6)
    }
}