import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyItem.aiPriorityScore, order: .reverse) private var studyItems: [StudyItem]
    @Query(sort: \LearningAnalytics.date, order: .reverse) private var analytics: [LearningAnalytics]
    @Query(sort: \StudyPlan.date, order: .reverse) private var plans: [StudyPlan]

    @State private var showingAddItem = false
    @State private var showingActiveSession = false
    @State private var sessionTargetItem: StudyItem?
    @State private var sessionPlannedMinutes: Int = 25

    private var activeItems: [StudyItem] {
        studyItems.filter { !$0.isArchived && !$0.isCompleted }
    }

    private var todayAnalytics: LearningAnalytics? {
        let today = Calendar.current.startOfDay(for: Date())
        return analytics.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var topPriorityItems: [StudyItem] {
        Array(activeItems.prefix(3))
    }

    private var itemsNeedingReview: [StudyItem] {
        activeItems.filter { $0.needsReview }
    }

    private var todayPlan: StudyPlan? {
        plans.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 朝活スコアカード
                    MorningScoreCard(analytics: todayAnalytics)

                    // 今日の学習目標
                    TodayGoalCard(
                        totalMinutes: todayAnalytics?.totalMinutes ?? 0,
                        goalMinutes: 120
                    )

                    // AI推奨学習項目
                    if !topPriorityItems.isEmpty {
                        AIRecommendationCard(items: topPriorityItems)
                    }

                    // 復習が必要な項目
                    if !itemsNeedingReview.isEmpty {
                        ReviewReminderCard(items: itemsNeedingReview)
                    }

                    // クイックアクション
                    QuickActionsCard(
                        showingAddItem: $showingAddItem,
                        onStartStudy: {
                            if let item = topPriorityItems.first {
                                sessionTargetItem = item
                                sessionPlannedMinutes = item.category.recommendedSessionMinutes
                                showingActiveSession = true
                            }
                        },
                        onStartReview: {
                            if let item = itemsNeedingReview.first {
                                sessionTargetItem = item
                                sessionPlannedMinutes = item.category.recommendedSessionMinutes
                                showingActiveSession = true
                            }
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("ダッシュボード")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddStudyItemView()
            }
            .fullScreenCover(isPresented: $showingActiveSession) {
                if let item = sessionTargetItem {
                    ActiveSessionView(
                        studyItem: item,
                        plannedMinutes: sessionPlannedMinutes,
                        onComplete: { session in
                            handleSessionComplete(session: session, item: item)
                            showingActiveSession = false
                        }
                    )
                }
            }
        }
    }

    private func handleSessionComplete(session: StudySession, item: StudyItem) {
        let engine = SpacedRepetitionEngine()
        engine.updateItemAfterSession(item: item, session: session)

        if let analytics = todayAnalytics {
            analytics.recordSession(session, category: item.category)
        } else {
            let newAnalytics = LearningAnalytics(date: Date())
            modelContext.insert(newAnalytics)
            newAnalytics.recordSession(session, category: item.category)
        }

        todayPlan?.markItemCompleted(item.id, minutes: session.actualMinutes, isMorning: session.isMorningSession)
        try? modelContext.save()
    }
}

// MARK: - Morning Score Card

struct MorningScoreCard: View {
    let analytics: LearningAnalytics?

    private var score: Int {
        analytics?.morningScore ?? 0
    }

    private var streakDays: Int {
        analytics?.morningStreakDays ?? 0
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sunrise.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("朝活スコア")
                    .font(.headline)
                Spacer()
                if streakDays > 0 {
                    Label("\(streakDays)日連続", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                Text("/ 100")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(score), total: 100)
                .tint(scoreColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Today Goal Card

struct TodayGoalCard: View {
    let totalMinutes: Int
    let goalMinutes: Int

    private var progress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(Double(totalMinutes) / Double(goalMinutes), 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundStyle(Color("AsaCoffeeBrown"))
                Text("今日の学習")
                    .font(.headline)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(totalMinutes)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("/ \(goalMinutes) 分")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(Color("AsaCoffeeBrown"))

            if progress >= 1.0 {
                Label("目標達成！", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - AI Recommendation Card

struct AIRecommendationCard: View {
    let items: [StudyItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("AI推奨")
                    .font(.headline)
                Spacer()
            }

            ForEach(items) { item in
                HStack {
                    Text(item.category.emoji)
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        HStack {
                            Text(item.difficulty.displayName)
                                .font(.caption)
                                .foregroundStyle(item.difficulty.color)
                            if let days = item.daysUntilTarget {
                                Text("・")
                                    .foregroundStyle(.secondary)
                                Text(days < 0 ? "期限切れ" : "あと\(days)日")
                                    .font(.caption)
                                    .foregroundStyle(days < 0 ? .red : .secondary)
                            }
                        }
                    }
                    Spacer()
                    PriorityBadge(score: item.aiPriorityScore)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
    let score: Double

    private var level: String {
        switch score {
        case 0.7...1.0: return "高"
        case 0.4..<0.7: return "中"
        default: return "低"
        }
    }

    private var color: Color {
        switch score {
        case 0.7...1.0: return .red
        case 0.4..<0.7: return .orange
        default: return .green
        }
    }

    var body: some View {
        Text(level)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Review Reminder Card

struct ReviewReminderCard: View {
    let items: [StudyItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("復習が必要")
                    .font(.headline)
                Spacer()
                Text("\(items.count)件")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(items.prefix(3)) { item in
                HStack {
                    Text(item.category.emoji)
                    Text(item.title)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text(item.masteryLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Quick Actions Card

struct QuickActionsCard: View {
    @Binding var showingAddItem: Bool
    let onStartStudy: () -> Void
    let onStartReview: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("クイックアクション")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus",
                    title: "追加",
                    color: Color("AsaCoffeeBrown")
                ) {
                    showingAddItem = true
                }

                QuickActionButton(
                    icon: "play.fill",
                    title: "学習開始",
                    color: .green
                ) {
                    onStartStudy()
                }

                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "復習",
                    color: .blue
                ) {
                    onStartReview()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [
            StudyItem.self,
            StudySession.self,
            StudyPlan.self,
            LearningAnalytics.self,
            UserLearningProfile.self
        ], inMemory: true)
}
