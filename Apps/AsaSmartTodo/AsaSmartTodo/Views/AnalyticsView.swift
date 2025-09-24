import SwiftUI
import AsaUIKit
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var viewModel: SmartTodoViewModel
    @State private var selectedPeriod: AnalyticsPeriod = .week
    @State private var isGeneratingReport = false

    var body: some View {
        ZStack {
            AsaColors.softCream.opacity(0.3)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択
                    periodSelector

                    // サマリーカード
                    if let report = viewModel.weeklyReport {
                        WeeklySummaryCard(report: report)
                    } else if let analytics = viewModel.todayAnalytics {
                        DailySummaryCard(analytics: analytics)
                    }

                    // 生産性グラフ
                    productivityChart

                    // カテゴリ分析
                    categoryAnalysis

                    // 朝活パフォーマンス
                    morningPerformance

                    // AI学習進捗
                    aiLearningProgress

                    // レポート生成ボタン
                    generateReportButton
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            if viewModel.weeklyReport == nil {
                generateWeeklyReport()
            }
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker("期間", selection: $selectedPeriod) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }

    // MARK: - Productivity Chart

    private var productivityChart: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(AsaColors.coffeeBrown)
                    Text("生産性トレンド")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                }

                // 時系列データの生成（サンプル）
                let data = generateProductivityData()

                Chart(data) { item in
                    LineMark(
                        x: .value("日", item.day),
                        y: .value("タスク完了数", item.completed)
                    )
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("日", item.day),
                        y: .value("タスク完了数", item.completed)
                    )
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .symbolSize(50)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let day = value.as(String.self) {
                                Text(day)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }

    // MARK: - Category Analysis

    private var categoryAnalysis: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.pie")
                        .foregroundColor(AsaColors.mocha)
                    Text("カテゴリ別完了率")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                }

                let categoryData = generateCategoryData()

                ForEach(categoryData, id: \.category) { item in
                    CategoryProgressRow(item: item)
                }

                // 円グラフ（簡易版）
                if !categoryData.isEmpty {
                    ZStack {
                        ForEach(Array(categoryData.enumerated()), id: \.element.category) { index, item in
                            CircleSegment(
                                startAngle: calculateStartAngle(for: index, in: categoryData),
                                endAngle: calculateEndAngle(for: index, in: categoryData),
                                color: categoryColor(item.category)
                            )
                        }
                    }
                    .frame(height: 150)
                    .padding(.top)
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }

    // MARK: - Morning Performance

    private var morningPerformance: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sunrise")
                        .foregroundColor(Color.orange)
                    Text("朝活パフォーマンス")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                }

                // 朝活スコアゲージ
                if let analytics = viewModel.todayAnalytics {
                    MorningScoreGauge(score: analytics.earlyMorningProductivityScore)

                    // 時間帯別タスク完了数
                    HStack(spacing: 0) {
                        ForEach(5..<8) { hour in
                            TimeSlotIndicator(
                                hour: hour,
                                isActive: hasTasksInHour(hour),
                                count: countTasksInHour(hour)
                            )
                        }
                    }
                    .padding(.top)

                    // 推奨事項
                    if analytics.earlyMorningProductivityScore < 0.3 {
                        RecommendationBox(
                            text: "朝活を始めてみましょう！5:00-7:00の時間帯は集中力が高く、重要なタスクに最適です。",
                            icon: "lightbulb",
                            color: Color.orange
                        )
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }

    // MARK: - AI Learning Progress

    private var aiLearningProgress: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(AsaColors.mocha)
                    Text("AI学習進捗")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                }

                // 学習データ量
                let totalFeedback = viewModel.tasks.filter { $0.feedbackProvided }.count
                let positiveF feedbackCount = viewModel.tasks.filter { $0.feedbackProvided && ($0.feedbackIsPositive ?? false) }.count

                VStack(spacing: 12) {
                    LearningMetric(
                        label: "学習済みタスク",
                        value: totalFeedback,
                        total: viewModel.tasks.count,
                        icon: "graduationcap"
                    )

                    LearningMetric(
                        label: "予測採用率",
                        value: positiveFeedbackCount,
                        total: totalFeedback,
                        icon: "checkmark.circle"
                    )

                    // 精度向上グラフ
                    if totalFeedback >= 10 {
                        AccuracyTrendChart(accuracy: viewModel.aiAccuracyRate)
                    }

                    // マイルストーン
                    if totalFeedback < 10 {
                        MilestoneCard(
                            current: totalFeedback,
                            target: 10,
                            message: "あと\(10 - totalFeedback)件のフィードバックで基本学習完了"
                        )
                    } else if totalFeedback < 50 {
                        MilestoneCard(
                            current: totalFeedback,
                            target: 50,
                            message: "あと\(50 - totalFeedback)件で高精度予測が可能に"
                        )
                    } else {
                        CompletionBadge(
                            title: "学習済み",
                            subtitle: "AIは十分なデータを学習しました"
                        )
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }

    // MARK: - Generate Report Button

    private var generateReportButton: some View {
        VStack(spacing: 12) {
            AsaButton(
                title: isGeneratingReport ? "レポート生成中..." : "詳細レポートを生成",
                action: generateDetailedReport,
                color: AsaColors.coffeeBrown,
                isLoading: isGeneratingReport
            )

            Text("PDFでエクスポート機能は今後実装予定")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    // MARK: - Helper Methods

    private func generateProductivityData() -> [ProductivityData] {
        let calendar = Calendar.current
        var data: [ProductivityData] = []

        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ja_JP")
                formatter.dateFormat = "M/d"

                let completed = viewModel.tasks.filter { task in
                    guard let completedAt = task.completedAt else { return false }
                    return calendar.isDate(completedAt, inSameDayAs: date)
                }.count

                data.append(ProductivityData(
                    day: formatter.string(from: date),
                    completed: completed
                ))
            }
        }

        return data
    }

    private func generateCategoryData() -> [CategoryAnalyticsData] {
        var data: [CategoryAnalyticsData] = []

        for category in TaskCategory.allCases {
            let categoryTasks = viewModel.tasks.filter { $0.category == category }
            let completed = categoryTasks.filter { $0.status == .done }.count
            let total = categoryTasks.count

            if total > 0 {
                data.append(CategoryAnalyticsData(
                    category: category,
                    completed: completed,
                    total: total,
                    completionRate: Double(completed) / Double(total)
                ))
            }
        }

        return data.sorted { $0.completionRate > $1.completionRate }
    }

    private func calculateStartAngle(for index: Int, in data: [CategoryAnalyticsData]) -> Angle {
        let total = data.reduce(0) { $0 + $1.completed }
        var angle = -90.0
        for i in 0..<index {
            angle += (Double(data[i].completed) / Double(total)) * 360
        }
        return Angle(degrees: angle)
    }

    private func calculateEndAngle(for index: Int, in data: [CategoryAnalyticsData]) -> Angle {
        let total = data.reduce(0) { $0 + $1.completed }
        var angle = -90.0
        for i in 0...index {
            angle += (Double(data[i].completed) / Double(total)) * 360
        }
        return Angle(degrees: angle)
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

    private func hasTasksInHour(_ hour: Int) -> Bool {
        viewModel.tasks.contains { task in
            Calendar.current.component(.hour, from: task.createdAt) == hour
        }
    }

    private func countTasksInHour(_ hour: Int) -> Int {
        viewModel.tasks.filter { task in
            Calendar.current.component(.hour, from: task.createdAt) == hour
        }.count
    }

    private func generateWeeklyReport() {
        isGeneratingReport = true
        Task {
            await viewModel.generateWeeklyReport()
            await MainActor.run {
                isGeneratingReport = false
            }
        }
    }

    private func generateDetailedReport() {
        generateWeeklyReport()
    }
}

// MARK: - Supporting Types

enum AnalyticsPeriod: String, CaseIterable {
    case today = "今日"
    case week = "週間"
    case month = "月間"
}

struct ProductivityData {
    let day: String
    let completed: Int
}

struct CategoryAnalyticsData {
    let category: TaskCategory
    let completed: Int
    let total: Int
    let completionRate: Double
}

// MARK: - Components

struct WeeklySummaryCard: View {
    let report: WeeklyReport

    var body: some View {
        AsaCard {
            VStack(spacing: 16) {
                Text("週間サマリー")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                HStack(spacing: 20) {
                    SummaryMetric(
                        label: "完了タスク",
                        value: "\(report.totalTasksCompleted)",
                        icon: "checkmark.circle.fill"
                    )
                    SummaryMetric(
                        label: "完了率",
                        value: "\(Int(report.averageCompletionRate * 100))%",
                        icon: "percent"
                    )
                    SummaryMetric(
                        label: "AI精度",
                        value: "\(Int(report.aiAcceptanceRate * 100))%",
                        icon: "brain"
                    )
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    if let category = report.mostProductiveCategory {
                        Label("最も生産的: \(category)", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                    Label("最適時間帯: \(report.bestProductiveTimeSlot)", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(AsaColors.mocha)
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

struct DailySummaryCard: View {
    let analytics: TaskAnalytics

    var body: some View {
        AsaCard {
            VStack(spacing: 16) {
                Text("今日の実績")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                HStack(spacing: 20) {
                    SummaryMetric(
                        label: "作成",
                        value: "\(analytics.totalTasksCreated)",
                        icon: "plus.circle"
                    )
                    SummaryMetric(
                        label: "完了",
                        value: "\(analytics.totalTasksCompleted)",
                        icon: "checkmark.circle"
                    )
                    SummaryMetric(
                        label: "完了率",
                        value: "\(Int(analytics.completionRate * 100))%",
                        icon: "chart.pie"
                    )
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

struct SummaryMetric: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AsaColors.coffeeBrown)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.darkSlate)
            Text(label)
                .font(.caption2)
                .foregroundColor(AsaColors.mutedSage)
        }
    }
}

struct CategoryProgressRow: View {
    let item: CategoryAnalyticsData

    var body: some View {
        HStack {
            Label(item.category.rawValue, systemImage: categoryIcon(item.category))
                .font(.subheadline)
                .foregroundColor(AsaColors.darkSlate)

            Spacer()

            Text("\(item.completed)/\(item.total)")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)

            // プログレスバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AsaColors.softCream)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(categoryColor(item.category))
                        .frame(width: geometry.size.width * item.completionRate, height: 4)
                }
            }
            .frame(width: 60, height: 4)
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

struct CircleSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color.opacity(0.8))
        }
    }
}

struct MorningScoreGauge: View {
    let score: Double

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(AsaColors.softCream, lineWidth: 10)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: score)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(score * 100))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.darkSlate)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("朝活スコア")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.darkSlate)
                Text("5:00-7:00のタスク完了数")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }

            Spacer()
        }
    }
}

struct TimeSlotIndicator: View {
    let hour: Int
    let isActive: Bool
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(hour):00")
                .font(.caption2)
                .foregroundColor(AsaColors.mutedSage)

            RoundedRectangle(cornerRadius: 4)
                .fill(isActive ? Color.orange : AsaColors.softCream)
                .frame(height: 30)
                .overlay(
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isActive ? .white : AsaColors.mutedSage)
                )
        }
    }
}

struct LearningMetric: View {
    let label: String
    let value: Int
    let total: Int
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AsaColors.mocha)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(AsaColors.darkSlate)
                Text("\(value) / \(total)")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }

            Spacer()

            // プログレスリング
            ZStack {
                Circle()
                    .stroke(AsaColors.softCream, lineWidth: 4)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: total > 0 ? Double(value) / Double(total) : 0)
                    .stroke(AsaColors.mocha, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Text("\(Int((total > 0 ? Double(value) / Double(total) : 0) * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.darkSlate)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AccuracyTrendChart: View {
    let accuracy: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("精度向上トレンド")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)

            // 簡易的なトレンドインジケータ
            HStack(spacing: 2) {
                ForEach(0..<10) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Double(index) / 10.0 <= accuracy ? AsaColors.mocha : AsaColors.softCream)
                        .frame(height: 20)
                }
            }
        }
    }
}

struct MilestoneCard: View {
    let current: Int
    let target: Int
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "flag.checkered")
                .foregroundColor(AsaColors.coffeeBrown)

            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.caption)
                    .foregroundColor(AsaColors.darkSlate)

                ProgressView(value: Double(current), total: Double(target))
                    .tint(AsaColors.coffeeBrown)
            }
        }
        .padding(12)
        .background(AsaColors.softCream)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CompletionBadge: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(AsaColors.coffeeBrown)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.darkSlate)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AsaColors.softCream, AsaColors.softCream.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct RecommendationBox: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(text)
                .font(.caption)
                .foregroundColor(AsaColors.darkSlate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView()
        .environmentObject(SmartTodoViewModel())
}