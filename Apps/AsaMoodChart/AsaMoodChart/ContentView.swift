// AsaApps/Apps/AsaMoodChart/ContentView.swift
import SwiftUI
import AsaUIKit

/// メインのコンテンツビュー
struct ContentView: View {
    @State private var viewModel = MoodChartViewModel()
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // 期間フィルター
                periodFilterView
                
                // タブビュー
                TabView(selection: $selectedTab) {
                    // 線グラフ
                    lineChartTab
                        .tag(0)
                    
                    // 棒グラフ
                    barChartTab
                        .tag(1)
                    
                    // 円グラフ
                    pieChartTab
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // ページインジケーター（カスタム）
                pageIndicator
                
                // フッター
                footerView
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationBarHidden(true)
        }
        .refreshable {
            await refreshData()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                // ロゴ・タイトル
                VStack(alignment: .leading, spacing: 4) {
                    Text("AsaMoodChart")
                        .font(.largeTitle.bold())
                        .foregroundColor(AsaColors.coffeeBrown)
                    
                    Text("気分データの可視化")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)
                }
                
                Spacer()
                
                // 更新ボタン
                AsaButton(
                    title: "更新",
                    action: {
                        Task {
                            await refreshData()
                        }
                    },
                    color: AsaColors.mutedSage,
                    isEnabled: !isRefreshing
                )
            }
            
            // 統計概要
            statisticsSummary
        }
        .padding()
        .background(AsaColors.cardBackground)
        .shadow(color: AsaColors.darkSlate.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var statisticsSummary: some View {
        HStack(spacing: 20) {
            summaryItem(
                title: "記録数",
                value: "\(viewModel.totalRecordDays)",
                icon: "📊"
            )
            
            summaryItem(
                title: "平均気分",
                value: String(format: "%.1f", viewModel.averageMoodValue),
                icon: "📈"
            )
            
            summaryItem(
                title: "最頻気分",
                value: viewModel.mostFrequentMood,
                icon: "🏆"
            )
        }
    }
    
    @ViewBuilder
    private func summaryItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title3)
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(AsaColors.coffeeBrown)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var periodFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimePeriod.allCases) { period in
                    periodFilterButton(for: period)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(AsaColors.cardBackground)
    }
    
    @ViewBuilder
    private func periodFilterButton(for period: TimePeriod) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.changePeriod(to: period)
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
    
    @ViewBuilder
    private var lineChartTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                LineChartView(moodEntries: viewModel.sortedMoodEntries)
                
                // 期間の説明
                periodDescription
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // タブバー分の余白
        }
    }
    
    @ViewBuilder
    private var barChartTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                BarChartView(moodEntries: viewModel.filteredMoodEntries)
                
                // 期間の説明
                periodDescription
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // タブバー分の余白
        }
    }
    
    @ViewBuilder
    private var pieChartTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                PieChartView(moodEntries: viewModel.filteredMoodEntries)
                
                // 期間の説明
                periodDescription
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // タブバー分の余白
        }
    }
    
    @ViewBuilder
    private var periodDescription: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("📅 表示期間")
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                    
                    Spacer()
                    
                    Text(viewModel.selectedPeriod.rawValue)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(AsaColors.softCream)
                        .cornerRadius(8)
                }
                
                Text(viewModel.selectedPeriod.description)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
    }
    
    @ViewBuilder
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(selectedTab == index ? AsaColors.coffeeBrown : AsaColors.mutedSage)
                    .frame(width: 8, height: 8)
                    .scaleEffect(selectedTab == index ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var footerView: some View {
        VStack(spacing: 8) {
            // グラフタイプの説明
            HStack(spacing: 16) {
                footerTabItem(
                    title: "時系列",
                    icon: "chart.line.uptrend.xyaxis",
                    isSelected: selectedTab == 0
                ) {
                    withAnimation(.easeInOut) { selectedTab = 0 }
                }
                
                footerTabItem(
                    title: "分析",
                    icon: "chart.bar.xaxis",
                    isSelected: selectedTab == 1
                ) {
                    withAnimation(.easeInOut) { selectedTab = 1 }
                }
                
                footerTabItem(
                    title: "分布",
                    icon: "chart.pie",
                    isSelected: selectedTab == 2
                ) {
                    withAnimation(.easeInOut) { selectedTab = 2 }
                }
            }
            
            // データソース情報
            Text("データソース: AsaMoodTracker")
                .font(.caption2)
                .foregroundColor(AsaColors.mutedSage.opacity(0.7))
                .padding(.bottom, 8)
        }
        .padding()
        .background(AsaColors.cardBackground)
        .shadow(color: AsaColors.darkSlate.opacity(0.1), radius: 2, x: 0, y: -1)
    }
    
    @ViewBuilder
    private func footerTabItem(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? AsaColors.coffeeBrown : AsaColors.mutedSage)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? AsaColors.coffeeBrown : AsaColors.mutedSage)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Methods
    
    @MainActor
    private func refreshData() async {
        isRefreshing = true
        
        // アニメーション付きで更新
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.refreshData()
        }
        
        // 少し待ってからフラグをリセット
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        isRefreshing = false
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}