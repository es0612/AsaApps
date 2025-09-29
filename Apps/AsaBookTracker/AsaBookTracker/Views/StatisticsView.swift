// AsaApps/Apps/AsaBookTracker/Views/StatisticsView.swift
import SwiftUI
import Charts
import AsaUIKit

/// 読書統計データを表示するビュー
struct StatisticsView: View {
    @Bindable var viewModel: StatisticsViewModel
    @State private var selectedChart: StatisticsChartType = .readingProgress
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // 期間選択
                periodSelectorView
                
                // 統計概要
                overallStatsView
                
                // チャート表示
                chartView
                
                Spacer()
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("読書統計")
                    .font(.largeTitle.bold())
                    .foregroundColor(AsaColors.coffeeBrown)
                
                Text("読書データの分析")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)
            }
            
            Spacer()
        }
        .padding()
        .background(AsaColors.cardBackground)
        .shadow(color: AsaColors.darkSlate.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var periodSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StatisticsPeriod.allCases) { period in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedPeriod = period
                        }
                    }) {
                        Text(period.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(
                                viewModel.selectedPeriod == period ? .white : AsaColors.coffeeBrown
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedPeriod == period ? 
                                AsaColors.coffeeBrown : AsaColors.softCream
                            )
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(AsaColors.cardBackground)
    }
    
    @ViewBuilder
    private var overallStatsView: some View {
        AsaCard {
            VStack(spacing: 16) {
                Text("📊 概要統計")
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                let stats = viewModel.overallStatistics
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatisticCard(
                        icon: "books.vertical",
                        title: "総冊数",
                        value: "\(stats.totalBooks)",
                        subtitle: "冊"
                    )
                    
                    StatisticCard(
                        icon: "checkmark.circle.fill",
                        title: "完読",
                        value: "\(stats.completedBooks)",
                        subtitle: "冊完了"
                    )
                    
                    StatisticCard(
                        icon: "book",
                        title: "読書中",
                        value: "\(stats.currentlyReading)",
                        subtitle: "冊"
                    )
                    
                    StatisticCard(
                        icon: "doc.text",
                        title: "読了ページ",
                        value: "\(stats.totalPagesRead)",
                        subtitle: "ページ"
                    )
                    
                    StatisticCard(
                        icon: "clock",
                        title: "読書時間",
                        value: "\(stats.totalReadingHours)",
                        subtitle: "時間"
                    )
                    
                    StatisticCard(
                        icon: "percent",
                        title: "完了率",
                        value: String(format: "%.0f", stats.completionRate * 100),
                        subtitle: "%"
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var chartView: some View {
        AsaCard {
            VStack(spacing: 16) {
                // チャート選択
                HStack {
                    Text("📈 詳細分析")
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                    
                    Spacer()
                    
                    Picker("チャート", selection: $selectedChart) {
                        ForEach(StatisticsChartType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AsaColors.coffeeBrown)
                }
                
                // チャート表示エリア
                Group {
                    switch selectedChart {
                    case .readingProgress:
                        readingProgressChart
                    case .genreDistribution:
                        genreDistributionChart
                    case .monthlyTrend:
                        monthlyTrendChart
                    case .dailyActivity:
                        dailyActivityChart
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 100) // タブバー分の余白
    }
    
    @ViewBuilder
    private var readingProgressChart: some View {
        let data = viewModel.readingProgressData.prefix(10) // 上位10冊
        
        if data.isEmpty {
            Text("表示するデータがありません")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(Array(data), id: \.bookTitle) { book in
                BarMark(
                    x: .value("冊数", book.completionRatio),
                    y: .value("本", book.bookTitle)
                )
                .foregroundStyle(AsaColors.coffeeBrown.gradient)
                .cornerRadius(4)
            }
            .chartXScale(domain: 0...1)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let ratio = value.as(Double.self) {
                            Text("\(Int(ratio * 100))%")
                                .font(.caption)
                                .foregroundColor(AsaColors.darkSlate)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let title = value.as(String.self) {
                            Text(title.count > 15 ? String(title.prefix(12)) + "..." : title)
                                .font(.caption2)
                                .foregroundColor(AsaColors.darkSlate)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var genreDistributionChart: some View {
        let data = viewModel.genreDistributionData
        
        if data.isEmpty {
            Text("表示するデータがありません")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(data, id: \.genre) { genreData in
                SectorMark(
                    angle: .value("冊数", genreData.count),
                    innerRadius: .ratio(0.4),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("ジャンル", genreData.genre))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale(range: [
                AsaColors.coffeeBrown,
                AsaColors.mocha,
                AsaColors.mutedSage,
                AsaColors.darkSlate,
                .blue,
                .green,
                .orange,
                .purple
            ])
            .chartBackground { proxy in
                VStack(spacing: 4) {
                    Text("\(data.reduce(0) { $0 + $1.count })")
                        .font(.title2.bold())
                        .foregroundColor(AsaColors.coffeeBrown)
                    
                    Text("総冊数")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
        }
    }
    
    @ViewBuilder
    private var monthlyTrendChart: some View {
        let data = viewModel.monthlyReadingData
        
        if data.isEmpty {
            Text("表示するデータがありません")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(data, id: \.month) { monthData in
                LineMark(
                    x: .value("月", monthData.month),
                    y: .value("完読冊数", monthData.booksCompleted)
                )
                .foregroundStyle(AsaColors.coffeeBrown)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                
                PointMark(
                    x: .value("月", monthData.month),
                    y: .value("完読冊数", monthData.booksCompleted)
                )
                .foregroundStyle(AsaColors.coffeeBrown)
                .symbolSize(60)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let count = value.as(Int.self) {
                            Text("\(count)冊")
                                .font(.caption)
                                .foregroundColor(AsaColors.darkSlate)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var dailyActivityChart: some View {
        let data = viewModel.dailyReadingData.suffix(14) // 過去14日間
        
        if data.isEmpty {
            Text("表示するデータがありません")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(Array(data), id: \.day) { dayData in
                BarMark(
                    x: .value("日", dayData.day),
                    y: .value("読書時間", dayData.readingMinutes)
                )
                .foregroundStyle(AsaColors.mutedSage.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let minutes = value.as(Int.self) {
                            Text("\(minutes)分")
                                .font(.caption)
                                .foregroundColor(AsaColors.darkSlate)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - StatisticCard

struct StatisticCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AsaColors.coffeeBrown)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(AsaColors.darkSlate)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AsaColors.mutedSage)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(AsaColors.darkSlate.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AsaColors.softCream.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    StatisticsView(viewModel: StatisticsViewModel())
}