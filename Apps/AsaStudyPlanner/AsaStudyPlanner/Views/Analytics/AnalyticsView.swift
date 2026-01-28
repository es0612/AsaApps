import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LearningAnalytics.date, order: .reverse) private var analytics: [LearningAnalytics]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    @State private var selectedPeriod: AnalyticsPeriod = .week

    enum AnalyticsPeriod: String, CaseIterable {
        case week = "週間"
        case month = "月間"
        case all = "全期間"
    }

    private var filteredAnalytics: [LearningAnalytics] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return analytics.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return analytics.filter { $0.date >= monthAgo }
        case .all:
            return analytics
        }
    }

    private var totalMinutes: Int {
        filteredAnalytics.reduce(0) { $0 + $1.totalMinutes }
    }

    private var totalSessions: Int {
        filteredAnalytics.reduce(0) { $0 + $1.completedSessions }
    }

    private var averageFocus: Double {
        let validAnalytics = filteredAnalytics.filter { $0.averageFocusLevel > 0 }
        guard !validAnalytics.isEmpty else { return 0 }
        return validAnalytics.reduce(0) { $0 + $1.averageFocusLevel } / Double(validAnalytics.count)
    }

    private var morningMinutes: Int {
        filteredAnalytics.reduce(0) { $0 + $1.morningMinutes }
    }

    private var currentStreak: Int {
        analytics.first?.streakDays ?? 0
    }

    private var morningStreak: Int {
        analytics.first?.morningStreakDays ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間セレクター
                    Picker("期間", selection: $selectedPeriod) {
                        ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // 概要カード
                    SummaryCardsView(
                        totalMinutes: totalMinutes,
                        totalSessions: totalSessions,
                        averageFocus: averageFocus,
                        morningMinutes: morningMinutes
                    )

                    // ストリーク
                    StreakCardsView(
                        currentStreak: currentStreak,
                        morningStreak: morningStreak
                    )

                    // 週間チャート
                    if !filteredAnalytics.isEmpty {
                        WeeklyChartView(analytics: filteredAnalytics)
                    }

                    // カテゴリ別統計
                    CategoryStatsView(analytics: filteredAnalytics)

                    // AI採用率
                    AIAcceptanceView(analytics: filteredAnalytics)
                }
                .padding()
            }
            .navigationTitle("学習分析")
        }
    }
}

// MARK: - Summary Cards

struct SummaryCardsView: View {
    let totalMinutes: Int
    let totalSessions: Int
    let averageFocus: Double
    let morningMinutes: Int

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(
                title: "総学習時間",
                value: formatTime(totalMinutes),
                icon: "clock.fill",
                color: Color("AsaCoffeeBrown")
            )

            SummaryCard(
                title: "セッション数",
                value: "\(totalSessions)回",
                icon: "flame.fill",
                color: .orange
            )

            SummaryCard(
                title: "平均集中度",
                value: String(format: "%.1f", averageFocus),
                icon: "brain.head.profile",
                color: .purple
            )

            SummaryCard(
                title: "朝活時間",
                value: formatTime(morningMinutes),
                icon: "sunrise.fill",
                color: .yellow
            )
        }
    }

    private func formatTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)時間\(mins)分"
        }
        return "\(minutes)分"
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Streak Cards

struct StreakCardsView: View {
    let currentStreak: Int
    let morningStreak: Int

    var body: some View {
        HStack(spacing: 12) {
            StreakCard(
                title: "連続学習",
                days: currentStreak,
                icon: "flame.fill",
                color: .orange
            )

            StreakCard(
                title: "連続朝活",
                days: morningStreak,
                icon: "sunrise.fill",
                color: .yellow
            )
        }
    }
}

struct StreakCard: View {
    let title: String
    let days: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            VStack(alignment: .leading) {
                Text("\(days)日")
                    .font(.title2.bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Weekly Chart

struct WeeklyChartView: View {
    let analytics: [LearningAnalytics]

    private var last7Days: [(date: Date, minutes: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let minutes = analytics.first { calendar.isDate($0.date, inSameDayAs: date) }?.totalMinutes ?? 0
            return (date, minutes)
        }
    }

    private var maxMinutes: Int {
        max(last7Days.map(\.minutes).max() ?? 60, 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週間学習時間")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(last7Days, id: \.date) { day in
                    VStack(spacing: 4) {
                        Text("\(day.minutes)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(for: day.minutes))
                            .frame(height: CGFloat(day.minutes) / CGFloat(maxMinutes) * 100)

                        Text(dayLabel(for: day.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func barColor(for minutes: Int) -> Color {
        if minutes >= 60 {
            return .green
        } else if minutes >= 30 {
            return Color("AsaCoffeeBrown")
        } else if minutes > 0 {
            return .orange
        } else {
            return Color(.systemGray5)
        }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Category Stats

struct CategoryStatsView: View {
    let analytics: [LearningAnalytics]

    private var categoryTotals: [(category: StudyCategory, minutes: Int)] {
        var totals: [String: Int] = [:]

        for analytic in analytics {
            for (categoryRaw, minutes) in analytic.categoryMinutes {
                totals[categoryRaw, default: 0] += minutes
            }
        }

        return totals.compactMap { (categoryRaw, minutes) in
            guard let category = StudyCategory(rawValue: categoryRaw) else { return nil }
            return (category, minutes)
        }.sorted { $0.minutes > $1.minutes }
    }

    private var totalMinutes: Int {
        categoryTotals.reduce(0) { $0 + $1.minutes }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ別学習時間")
                .font(.headline)

            if categoryTotals.isEmpty {
                Text("データがありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(categoryTotals.prefix(5), id: \.category) { item in
                    HStack {
                        Text(item.category.emoji)
                        Text(item.category.displayName)
                            .font(.subheadline)

                        Spacer()

                        Text("\(item.minutes)分")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // パーセンテージバー
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color("AsaCoffeeBrown").opacity(0.3))
                                .frame(width: geometry.size.width)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color("AsaCoffeeBrown"))
                                        .frame(width: geometry.size.width * CGFloat(item.minutes) / CGFloat(max(totalMinutes, 1)))
                                }
                        }
                        .frame(width: 60, height: 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - AI Acceptance

struct AIAcceptanceView: View {
    let analytics: [LearningAnalytics]

    private var totalAccepted: Int {
        analytics.reduce(0) { $0 + $1.aiAcceptedCount }
    }

    private var totalRejected: Int {
        analytics.reduce(0) { $0 + $1.aiRejectedCount }
    }

    private var acceptanceRate: Double {
        let total = totalAccepted + totalRejected
        guard total > 0 else { return 0 }
        return Double(totalAccepted) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("AI最適化の精度")
                    .font(.headline)
            }

            if totalAccepted + totalRejected == 0 {
                Text("AI提案へのフィードバックがまだありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text(String(format: "%.0f%%", acceptanceRate * 100))
                            .font(.title.bold())
                            .foregroundStyle(.purple)
                        Text("採用率")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(totalAccepted)")
                            .font(.headline)
                            .foregroundStyle(.green)
                        Text("採用")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .trailing) {
                        Text("\(totalRejected)")
                            .font(.headline)
                            .foregroundStyle(.red)
                        Text("却下")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading)
                }

                ProgressView(value: acceptanceRate)
                    .tint(.purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [
            StudyItem.self,
            StudySession.self,
            StudyPlan.self,
            LearningAnalytics.self,
            UserLearningProfile.self
        ], inMemory: true)
}
