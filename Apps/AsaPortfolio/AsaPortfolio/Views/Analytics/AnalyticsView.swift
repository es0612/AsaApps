import SwiftUI
import SwiftData
import Charts

/// 分析ビュー
struct AnalyticsView: View {
    @Bindable var viewModel: PortfolioViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isEmpty {
                    EmptyAnalyticsView()
                } else {
                    VStack(spacing: 20) {
                        // パフォーマンスサマリー
                        PerformanceSummaryCard(viewModel: viewModel)

                        // 資産推移チャート
                        portfolioPerformanceChart

                        // セクター配分
                        SectorAllocationChart(
                            sectorAllocations: viewModel.sectorAllocation
                        )

                        // 資産タイプ配分
                        AssetTypeAllocationChart(
                            assetTypeAllocations: viewModel.assetTypeAllocation
                        )

                        // 損益ランキング
                        GainLossBarChart(
                            holdings: viewModel.allHoldings,
                            title: "損益率ランキング"
                        )

                        // 上位銘柄・下位銘柄
                        TopPerformersSection(viewModel: viewModel)
                    }
                    .padding()
                }
            }
            .background(Color("AsaDarkSlate").opacity(0.05))
            .navigationTitle("分析")
        }
    }

    private var portfolioPerformanceChart: some View {
        // モックデータ（実際のアプリでは履歴データを使用）
        let mockData: [ChartDataPoint] = {
            var data: [ChartDataPoint] = []
            var value = viewModel.totalCost
            let dailyChange = (viewModel.totalValue - viewModel.totalCost) / 30

            for i in 0..<30 {
                let date = Calendar.current.date(byAdding: .day, value: -29 + i, to: Date())!
                value += dailyChange + Decimal(Double.random(in: -100...100))
                data.append(ChartDataPoint(date: date, value: max(value, 0)))
            }
            return data
        }()

        return PerformanceLineChart(
            data: mockData,
            title: "資産推移"
        )
    }
}

// MARK: - Performance Summary Card

struct PerformanceSummaryCard: View {
    let viewModel: PortfolioViewModel

    var body: some View {
        VStack(spacing: 16) {
            // メイン指標
            HStack(spacing: 20) {
                MetricItem(
                    title: "時価総額",
                    value: viewModel.totalValue.formattedCurrency,
                    color: Color("AsaCoffeeBrown")
                )

                Divider()
                    .frame(height: 40)

                MetricItem(
                    title: "取得原価",
                    value: viewModel.totalCost.formattedCurrency,
                    color: Color("AsaDarkSlate")
                )
            }

            Divider()

            // 損益指標
            HStack(spacing: 20) {
                MetricItem(
                    title: "含み損益",
                    value: viewModel.totalGain.formattedCurrency,
                    color: viewModel.totalGain >= 0 ? .green : .red,
                    showArrow: true,
                    isPositive: viewModel.totalGain >= 0
                )

                Divider()
                    .frame(height: 40)

                MetricItem(
                    title: "損益率",
                    value: viewModel.totalGainPercentage.formattedPercentage,
                    color: viewModel.totalGain >= 0 ? .green : .red,
                    showArrow: true,
                    isPositive: viewModel.totalGain >= 0
                )
            }

            Divider()

            // 追加指標
            HStack(spacing: 20) {
                MetricItem(
                    title: "ポートフォリオ数",
                    value: "\(viewModel.portfolios.count)",
                    color: Color("AsaMutedSage")
                )

                Divider()
                    .frame(height: 40)

                MetricItem(
                    title: "保有銘柄数",
                    value: "\(viewModel.allHoldings.count)",
                    color: Color("AsaMutedSage")
                )

                Divider()
                    .frame(height: 40)

                MetricItem(
                    title: "ウォッチ",
                    value: "\(viewModel.watchlistItems.count)",
                    color: Color("AsaMutedSage")
                )
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct MetricItem: View {
    let title: String
    let value: String
    let color: Color
    var showArrow: Bool = false
    var isPositive: Bool = true

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                if showArrow {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                }
                Text(value)
                    .font(.subheadline.bold())
            }
            .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Top Performers Section

struct TopPerformersSection: View {
    let viewModel: PortfolioViewModel

    var body: some View {
        VStack(spacing: 16) {
            // 値上がり上位
            if !viewModel.topGainers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.green)
                        Text("値上がり上位")
                            .font(.headline)
                            .foregroundStyle(Color("AsaDarkSlate"))
                    }

                    ForEach(viewModel.topGainers) { holding in
                        PerformerRow(holding: holding)
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            }

            // 値下がり上位
            if !viewModel.topLosers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.red)
                        Text("値下がり上位")
                            .font(.headline)
                            .foregroundStyle(Color("AsaDarkSlate"))
                    }

                    ForEach(viewModel.topLosers) { holding in
                        PerformerRow(holding: holding)
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
        }
    }
}

struct PerformerRow: View {
    let holding: Holding

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.subheadline.bold())
                Text(holding.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.unrealizedGain.formattedCurrency)
                    .font(.subheadline.bold())
                    .foregroundStyle(holding.isProfit ? .green : .red)

                Text(holding.gainPercentage.formattedPercentage)
                    .font(.caption)
                    .foregroundStyle(holding.isProfit ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State

struct EmptyAnalyticsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(Color("AsaMutedSage"))

            Text("分析データがありません")
                .font(.title2.bold())
                .foregroundStyle(Color("AsaDarkSlate"))

            Text("ポートフォリオに銘柄を追加すると\n詳細な分析が表示されます")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AnalyticsView(viewModel: PortfolioViewModel(
        stockAPIService: MockStockAPIService(),
        dataService: PortfolioDataService(modelContext: try! ModelContext(ModelContainer(for: Portfolio.self)))
    ))
}
