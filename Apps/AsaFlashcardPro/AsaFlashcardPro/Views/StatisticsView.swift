import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @Query private var flashcards: [Flashcard]
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingDetailStats = false
    
    enum TimeRange: String, CaseIterable {
        case today = "今日"
        case week = "今週"
        case month = "今月"
        case all = "全期間"
        
        var startDate: Date {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                return calendar.startOfDay(for: now)
            case .week:
                return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            case .month:
                return calendar.dateInterval(of: .month, for: now)?.start ?? now
            case .all:
                return Date.distantPast
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 時間範囲選択
                    TimeRangePicker(selectedRange: $selectedTimeRange)
                    
                    // 総合統計
                    OverallStatsView(
                        categories: categories,
                        flashcards: flashcards,
                        timeRange: selectedTimeRange
                    )
                    
                    // 学習進捗チャート
                    StudyProgressChartView(flashcards: flashcards, timeRange: selectedTimeRange)
                    
                    // カテゴリ別統計
                    CategoryStatsView(categories: categories, timeRange: selectedTimeRange)
                    
                    // 詳細統計
                    DetailedStatsView(flashcards: flashcards, timeRange: selectedTimeRange)
                    
                    // 学習傾向
                    LearningTrendsView(flashcards: flashcards, timeRange: selectedTimeRange)
                }
                .padding()
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDetailStats = true }) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .sheet(isPresented: $showingDetailStats) {
                DetailedStatisticsView(categories: categories, flashcards: flashcards)
            }
        }
    }
}

struct TimeRangePicker: View {
    @Binding var selectedRange: StatisticsView.TimeRange
    
    var body: some View {
        Picker("時間範囲", selection: $selectedRange) {
            ForEach(StatisticsView.TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}

struct OverallStatsView: View {
    let categories: [Category]
    let flashcards: [Flashcard]
    let timeRange: StatisticsView.TimeRange
    
    private var studiedFlashcards: [Flashcard] {
        flashcards.filter { flashcard in
            guard let lastStudied = flashcard.studyProgress.lastStudiedAt else { return false }
            return lastStudied >= timeRange.startDate
        }
    }
    
    private var totalAnswers: Int {
        studiedFlashcards.reduce(0) { $0 + $1.studyProgress.totalAnswers }
    }
    
    private var correctAnswers: Int {
        studiedFlashcards.reduce(0) { $0 + $1.studyProgress.correctAnswers }
    }
    
    private var overallCorrectRate: Double {
        guard totalAnswers > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalAnswers)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("学習概要")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color("AsaDarkSlate"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                OverallStatCard(
                    title: "総カテゴリ数",
                    value: "\\(categories.count)",
                    subtitle: "個",
                    icon: "folder.fill",
                    color: "AsaCoffeeBrown"
                )
                
                OverallStatCard(
                    title: "総単語数",
                    value: "\\(flashcards.count)",
                    subtitle: "枚",
                    icon: "doc.text.fill",
                    color: "AsaMocha"
                )
                
                OverallStatCard(
                    title: "学習した単語",
                    value: "\\(studiedFlashcards.count)",
                    subtitle: "枚",
                    icon: "checkmark.circle.fill",
                    color: "AsaMutedSage"
                )
                
                OverallStatCard(
                    title: "正解率",
                    value: "\\(Int(overallCorrectRate * 100))",
                    subtitle: "%",
                    icon: "percent",
                    color: "AsaDarkSlate"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("AsaSoftCream").opacity(0.2))
        )
    }
}

struct OverallStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(color))
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct StudyProgressChartView: View {
    let flashcards: [Flashcard]
    let timeRange: StatisticsView.TimeRange
    
    private var dailyStudyData: [DailyStudyData] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = timeRange.startDate
        
        var data: [DailyStudyData] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let studiedCount = flashcards.filter { flashcard in
                guard let lastStudied = flashcard.studyProgress.lastStudiedAt else { return false }
                return lastStudied >= dayStart && lastStudied < dayEnd
            }.count
            
            data.append(DailyStudyData(date: currentDate, studiedCount: studiedCount))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return data
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("学習進捗")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color("AsaDarkSlate"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if dailyStudyData.isEmpty {
                Text("データがありません")
                    .font(.subheadline)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                    .padding(.vertical, 40)
            } else {
                SimpleBarChartView(data: dailyStudyData)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct DailyStudyData: Identifiable {
    let id = UUID()
    let date: Date
    let studiedCount: Int
}

struct SimpleBarChartView: View {
    let data: [DailyStudyData]
    
    private var maxCount: Int {
        data.map(\.studiedCount).max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(data) { item in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("AsaCoffeeBrown"))
                        .frame(
                            width: max(20, (UIScreen.main.bounds.width - 80) / CGFloat(data.count) - 4),
                            height: max(4, CGFloat(item.studiedCount) / CGFloat(maxCount) * 100)
                        )
                    
                    if data.count <= 7 {
                        Text(item.date, format: .dateTime.weekday(.abbreviated))
                            .font(.caption2)
                            .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                    }
                }
            }
        }
        .frame(height: 120)
    }
}

struct CategoryStatsView: View {
    let categories: [Category]
    let timeRange: StatisticsView.TimeRange
    
    private var sortedCategories: [Category] {
        categories.sorted { $0.studyProgress > $1.studyProgress }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("カテゴリ別進捗")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color("AsaDarkSlate"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(sortedCategories) { category in
                CategoryProgressRow(category: category)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct CategoryProgressRow: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundColor(Color(category.color))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("\\(category.studiedFlashcards) / \\(category.totalFlashcards) 枚")
                    .font(.caption)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\\(Int(category.studyProgress * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(category.color))
                
                ProgressView(value: category.studyProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(category.color)))
                    .frame(width: 60)
                    .scaleEffect(y: 0.8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DetailedStatsView: View {
    let flashcards: [Flashcard]
    let timeRange: StatisticsView.TimeRange
    
    private var filteredFlashcards: [Flashcard] {
        flashcards.filter { flashcard in
            guard let lastStudied = flashcard.studyProgress.lastStudiedAt else { return false }
            return lastStudied >= timeRange.startDate
        }
    }
    
    private var averageCorrectRate: Double {
        guard !filteredFlashcards.isEmpty else { return 0.0 }
        let totalRate = filteredFlashcards.reduce(0.0) { $0 + $1.studyProgress.correctRate }
        return totalRate / Double(filteredFlashcards.count)
    }
    
    private var streakCounts: [Int: Int] {
        let streaks = filteredFlashcards.map { $0.studyProgress.streak }
        return Dictionary(grouping: streaks, by: { $0 }).mapValues { $0.count }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("詳細統計")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color("AsaDarkSlate"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                DetailStatItem(title: "平均正解率", value: "\\(Int(averageCorrectRate * 100))%", color: "AsaCoffeeBrown")
                DetailStatItem(title: "最高連続正解", value: "\\(streakCounts.keys.max() ?? 0)回", color: "AsaMutedSage")
                DetailStatItem(title: "苦手な単語", value: "\\(flashcards.filter { $0.difficultyLevel == .hard }.count)枚", color: "AsaMocha")
                DetailStatItem(title: "お気に入り", value: "\\(flashcards.filter { $0.isBookmarked }.count)枚", color: "AsaDarkSlate")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("AsaSoftCream").opacity(0.2))
        )
    }
}

struct DetailStatItem: View {
    let title: String
    let value: String
    let color: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(Color(color))
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct LearningTrendsView: View {
    let flashcards: [Flashcard]
    let timeRange: StatisticsView.TimeRange
    
    private var difficultyDistribution: [StudyLevel: Int] {
        let levels = flashcards.map { $0.difficultyLevel }
        return Dictionary(grouping: levels, by: { $0 }).mapValues { $0.count }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("学習傾向")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color("AsaDarkSlate"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ForEach(StudyLevel.allCases, id: \.self) { level in
                    let count = difficultyDistribution[level] ?? 0
                    let percentage = flashcards.isEmpty ? 0.0 : Double(count) / Double(flashcards.count)
                    
                    HStack {
                        Text(level.rawValue)
                            .font(.subheadline)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .frame(width: 60, alignment: .leading)
                        
                        ProgressView(value: percentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(level.color)))
                            .scaleEffect(y: 1.5)
                        
                        Text("\\(count)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color(level.color))
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct DetailedStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [Category]
    let flashcards: [Flashcard]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("詳細な統計情報")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    // ここにより詳細な統計を追加可能
                    Text("詳細統計機能は今後のアップデートで追加予定です。")
                        .font(.body)
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("詳細統計")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                }
            }
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [Category.self, Flashcard.self, StudyProgress.self], inMemory: true)
}