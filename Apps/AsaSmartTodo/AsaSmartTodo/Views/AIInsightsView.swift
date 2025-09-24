import SwiftUI
import AsaUIKit
import Charts

struct AIInsightsView: View {
    @EnvironmentObject private var viewModel: SmartTodoViewModel
    @State private var selectedInsightTab = 0

    var body: some View {
        ZStack {
            AsaColors.softCream.opacity(0.3)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // AI精度メトリクス
                    accuracyMetricsCard

                    // インサイトタブ
                    Picker("インサイトタイプ", selection: $selectedInsightTab) {
                        Text("予測分析").tag(0)
                        Text("パターン").tag(1)
                        Text("提案").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // タブ別コンテンツ
                    switch selectedInsightTab {
                    case 0:
                        predictionAnalysisView
                    case 1:
                        patternAnalysisView
                    case 2:
                        suggestionsView
                    default:
                        EmptyView()
                    }
                }
                .padding(.vertical)
            }
        }
    }

    // MARK: - Accuracy Metrics Card

    private var accuracyMetricsCard: some View {
        AsaCard {
            VStack(spacing: 16) {
                // ヘッダー
                HStack {
                    Image(systemName: "brain")
                        .font(.title2)
                        .foregroundColor(AsaColors.mocha)
                    Text("AI予測精度")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                }

                // 精度ゲージ
                AccuracyGauge(accuracy: viewModel.aiAccuracyRate)

                // 統計
                HStack(spacing: 20) {
                    MetricItem(
                        label: "採用率",
                        value: "\(Int(viewModel.aiAccuracyRate * 100))%",
                        icon: "checkmark.circle",
                        color: AsaColors.coffeeBrown
                    )

                    Divider()
                        .frame(height: 40)

                    MetricItem(
                        label: "総予測数",
                        value: "\(viewModel.tasks.filter { $0.feedbackProvided }.count)",
                        icon: "number",
                        color: AsaColors.mocha
                    )

                    Divider()
                        .frame(height: 40)

                    MetricItem(
                        label: "学習済み",
                        value: "\(viewModel.tasks.filter { $0.feedbackProvided && $0.status == .done }.count)",
                        icon: "graduationcap",
                        color: AsaColors.mutedSage
                    )
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }

    // MARK: - Prediction Analysis View

    private var predictionAnalysisView: some View {
        VStack(spacing: 16) {
            // 最近の予測
            AsaCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近のAI予測")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    if viewModel.tasks.filter({ !$0.feedbackProvided }).isEmpty {
                        Text("フィードバック待ちの予測はありません")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(viewModel.tasks.filter { !$0.feedbackProvided }.prefix(5), id: \.id) { task in
                            PredictionRow(task: task)
                                .onTapGesture {
                                    viewModel.selectedTask = task
                                    viewModel.showingTaskDetail = true
                                }
                        }
                    }
                }
                .padding()
            }
            .padding(.horizontal)

            // 優先度分布チャート
            if !viewModel.tasks.isEmpty {
                PriorityDistributionChart(tasks: viewModel.tasks)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Pattern Analysis View

    private var patternAnalysisView: some View {
        VStack(spacing: 16) {
            // 時間帯別パターン
            TimePatternCard(analytics: viewModel.todayAnalytics)
                .padding(.horizontal)

            // カテゴリ別パターン
            CategoryPatternCard(tasks: viewModel.tasks)
                .padding(.horizontal)

            // 朝活スコア
            if let analytics = viewModel.todayAnalytics {
                MorningProductivityCard(score: analytics.earlyMorningProductivityScore)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Suggestions View

    private var suggestionsView: some View {
        VStack(spacing: 16) {
            // AI提案カード
            ForEach(generateSuggestions(), id: \.title) { suggestion in
                SuggestionCard(suggestion: suggestion)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Helper Methods

    private func generateSuggestions() -> [AISuggestion] {
        var suggestions: [AISuggestion] = []

        // 朝活提案
        if let analytics = viewModel.todayAnalytics,
           analytics.earlyMorningProductivityScore < 0.5 {
            suggestions.append(AISuggestion(
                title: "朝活を始めてみましょう",
                description: "5:00-7:00の時間帯は集中力が高まります。重要なタスクをこの時間に配置することで生産性が向上します。",
                icon: "sunrise",
                color: Color.orange
            ))
        }

        // 期限管理提案
        let overdueCount = viewModel.overdueTasksCount
        if overdueCount > 2 {
            suggestions.append(AISuggestion(
                title: "期限管理の改善",
                description: "現在\(overdueCount)件のタスクが期限切れです。現実的な期限設定を心がけ、バッファを持たせることをお勧めします。",
                icon: "calendar.badge.exclamationmark",
                color: Color.red
            ))
        }

        // 優先度バランス提案
        let highPriorityCount = viewModel.tasks.filter { $0.userPriority == .high }.count
        let totalCount = viewModel.tasks.count
        if totalCount > 0 && Double(highPriorityCount) / Double(totalCount) > 0.5 {
            suggestions.append(AISuggestion(
                title: "優先度の見直し",
                description: "高優先度タスクが多すぎます。本当に緊急かつ重要なものだけを高優先度にし、他は中・低に振り分けましょう。",
                icon: "exclamationmark.triangle",
                color: AsaColors.coffeeBrown
            ))
        }

        // AI活用提案
        if viewModel.aiAccuracyRate < 0.5 && viewModel.tasks.filter({ $0.feedbackProvided }).count > 5 {
            suggestions.append(AISuggestion(
                title: "AI予測の改善",
                description: "AIの予測精度が低めです。フィードバックを増やすことで、より正確な優先度提案が可能になります。",
                icon: "brain",
                color: AsaColors.mocha
            ))
        }

        return suggestions
    }
}

// MARK: - Components

struct AccuracyGauge: View {
    let accuracy: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AsaColors.softCream, lineWidth: 20)

            Circle()
                .trim(from: 0, to: accuracy)
                .stroke(
                    LinearGradient(
                        colors: [AsaColors.coffeeBrown, AsaColors.mocha],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: accuracy)

            VStack(spacing: 4) {
                Text("\(Int(accuracy * 100))")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AsaColors.darkSlate)
                Text("パーセント")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
        .frame(width: 150, height: 150)
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.darkSlate)
            Text(label)
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
        }
    }
}

struct PredictionRow: View {
    let task: SmartTask
    @EnvironmentObject private var viewModel: SmartTodoViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(AsaColors.darkSlate)
                    .lineLimit(1)
                Text(task.predictionReason)
                    .font(.caption2)
                    .foregroundColor(AsaColors.mutedSage)
                    .lineLimit(1)
            }

            Spacer()

            // AI予測
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                PriorityBadge(priority: task.aiSuggestedPriority)
            }

            // フィードバックボタン
            HStack(spacing: 4) {
                Button {
                    viewModel.acceptAIPriority(for: task)
                } label: {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(AsaColors.coffeeBrown)
                }

                Button {
                    viewModel.rejectAIPriority(for: task)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        Text(priority.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(priorityColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var priorityColor: Color {
        switch priority {
        case .high:
            return Color.red
        case .medium:
            return AsaColors.coffeeBrown
        case .low:
            return AsaColors.mutedSage
        }
    }
}

struct TimePatternCard: View {
    let analytics: TaskAnalytics?

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("時間帯別生産性")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                if let analytics = analytics {
                    HStack(spacing: 16) {
                        TimeSlotBar(label: "朝", count: analytics.morningTasksCompleted, maxCount: 10)
                        TimeSlotBar(label: "昼", count: analytics.dayTasksCompleted, maxCount: 10)
                        TimeSlotBar(label: "夕", count: analytics.eveningTasksCompleted, maxCount: 10)
                        TimeSlotBar(label: "夜", count: analytics.nightTasksCompleted, maxCount: 10)
                    }
                } else {
                    Text("データがありません")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                        .padding(.vertical, 20)
                }
            }
            .padding()
        }
    }
}

struct TimeSlotBar: View {
    let label: String
    let count: Int
    let maxCount: Int

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(AsaColors.coffeeBrown.opacity(0.3))
                .frame(width: 40, height: 100)
                .overlay(
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AsaColors.coffeeBrown)
                                .frame(height: geometry.size.height * (Double(count) / Double(maxCount)))
                        }
                    }
                )

            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.darkSlate)

            Text(label)
                .font(.caption2)
                .foregroundColor(AsaColors.mutedSage)
        }
    }
}

struct CategoryPatternCard: View {
    let tasks: [SmartTask]

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("カテゴリ別タスク分布")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                let categoryGroups = Dictionary(grouping: tasks) { $0.category }

                ForEach(TaskCategory.allCases, id: \.self) { category in
                    let count = categoryGroups[category]?.count ?? 0
                    let total = tasks.count

                    HStack {
                        Label(category.rawValue, systemImage: categoryIcon(category))
                            .font(.caption)
                            .foregroundColor(AsaColors.darkSlate)

                        Spacer()

                        Text("\(count)件")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)

                        // プログレスバー
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AsaColors.softCream)
                                .frame(height: 4)
                                .overlay(
                                    HStack {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(categoryColor(category))
                                            .frame(width: total > 0 ? geometry.size.width * (Double(count) / Double(total)) : 0)
                                        Spacer()
                                    }
                                )
                        }
                        .frame(width: 100, height: 4)
                    }
                }
            }
            .padding()
        }
    }

    private func categoryIcon(_ category: TaskCategory) -> String {
        switch category {
        case .work: return "briefcase"
        case .personal: return "person"
        case .family: return "house"
        case .health: return "heart"
        case .learning: return "book"
        case .other: return "folder"
        }
    }

    private func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .work: return AsaColors.coffeeBrown
        case .family: return Color.blue
        case .health: return Color.green
        case .learning: return Color.purple
        case .personal: return Color.orange
        case .other: return AsaColors.mutedSage
        }
    }
}

struct MorningProductivityCard: View {
    let score: Double

    var body: some View {
        AsaCard {
            HStack {
                Image(systemName: "sunrise")
                    .font(.title)
                    .foregroundColor(Color.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("朝活スコア")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    Text("5:00-7:00の生産性")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                Spacer()

                Text("\(Int(score * 100))")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AsaColors.coffeeBrown)
                    + Text(" pt")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
            .padding()
        }
    }
}

struct SuggestionCard: View {
    let suggestion: AISuggestion

    var body: some View {
        AsaCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: suggestion.icon)
                    .font(.title2)
                    .foregroundColor(suggestion.color)

                VStack(alignment: .leading, spacing: 8) {
                    Text(suggestion.title)
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(AsaColors.darkSlate.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct PriorityDistributionChart: View {
    let tasks: [SmartTask]

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("優先度分布")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                let priorityGroups = Dictionary(grouping: tasks) { $0.userPriority }
                let highCount = priorityGroups[.high]?.count ?? 0
                let mediumCount = priorityGroups[.medium]?.count ?? 0
                let lowCount = priorityGroups[.low]?.count ?? 0

                Chart {
                    BarMark(
                        x: .value("優先度", "高"),
                        y: .value("件数", highCount)
                    )
                    .foregroundStyle(Color.red)

                    BarMark(
                        x: .value("優先度", "中"),
                        y: .value("件数", mediumCount)
                    )
                    .foregroundStyle(AsaColors.coffeeBrown)

                    BarMark(
                        x: .value("優先度", "低"),
                        y: .value("件数", lowCount)
                    )
                    .foregroundStyle(AsaColors.mutedSage)
                }
                .frame(height: 200)
                .chartXAxisLabel("優先度")
                .chartYAxisLabel("タスク数")
            }
            .padding()
        }
    }
}

// MARK: - Supporting Types

struct AISuggestion {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Preview

#Preview {
    AIInsightsView()
        .environmentObject(SmartTodoViewModel())
}