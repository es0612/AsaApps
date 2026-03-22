import SwiftUI
import SwiftData
import AsaUIKit

/// ダッシュボードビュー - 総資産と概要表示
struct DashboardView: View {
    @Bindable var viewModel: PortfolioViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 総資産カード
                    TotalValueCard(viewModel: viewModel)

                    // クイックアクション
                    QuickActionsRow(viewModel: viewModel)

                    // パフォーマンスサマリー
                    if !viewModel.isEmpty {
                        PerformanceSummarySection(viewModel: viewModel)
                    }

                    // ポートフォリオ一覧
                    if !viewModel.portfolios.isEmpty {
                        PortfolioSummarySection(viewModel: viewModel)
                    }

                    // 上位銘柄
                    if !viewModel.topHoldings.isEmpty {
                        TopHoldingsSection(viewModel: viewModel)
                    }
                }
                .padding()
            }
            .background(AsaColors.darkSlate.opacity(0.05))
            .navigationTitle("ダッシュボード")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refreshQuotes()
                        }
                    } label: {
                        if viewModel.isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isRefreshing)
                }
            }
            .refreshable {
                await viewModel.refreshQuotes()
            }
        }
    }
}

// MARK: - Total Value Card

struct TotalValueCard: View {
    let viewModel: PortfolioViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text("総資産")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(viewModel.totalValue.formattedCurrency)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(AsaColors.coffeeBrown)

            HStack(spacing: 16) {
                // 損益額
                VStack(alignment: .leading, spacing: 4) {
                    Text("含み損益")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(viewModel.totalGain.formattedCurrency)
                        .font(.headline)
                        .foregroundStyle(viewModel.totalGain >= 0 ? .green : .red)
                }

                Divider()
                    .frame(height: 30)

                // 損益率
                VStack(alignment: .leading, spacing: 4) {
                    Text("損益率")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: viewModel.totalGain >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)

                        Text(viewModel.totalGainPercentage.formattedPercentage)
                            .font(.headline)
                    }
                    .foregroundStyle(viewModel.totalGain >= 0 ? .green : .red)
                }

                Divider()
                    .frame(height: 30)

                // 銘柄数
                VStack(alignment: .leading, spacing: 4) {
                    Text("銘柄数")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(viewModel.allHoldings.count)")
                        .font(.headline)
                        .foregroundStyle(AsaColors.darkSlate)
                }
            }

            if let lastUpdated = viewModel.lastUpdated {
                Text("最終更新: \(lastUpdated, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Quick Actions Row

struct QuickActionsRow: View {
    let viewModel: PortfolioViewModel
    @State private var showAddPortfolio = false
    @State private var showAddHolding = false

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "ポートフォリオ追加",
                icon: "folder.badge.plus",
                color: AsaColors.coffeeBrown
            ) {
                showAddPortfolio = true
            }

            if viewModel.selectedPortfolio != nil {
                QuickActionButton(
                    title: "銘柄追加",
                    icon: "plus.circle",
                    color: AsaColors.mocha
                ) {
                    showAddHolding = true
                }
            }
        }
        .sheet(isPresented: $showAddPortfolio) {
            AddPortfolioSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showAddHolding) {
            if let portfolio = viewModel.selectedPortfolio {
                AddHoldingSheet(viewModel: viewModel, portfolio: portfolio)
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Performance Summary Section

struct PerformanceSummarySection: View {
    let viewModel: PortfolioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("パフォーマンス")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            HStack(spacing: 12) {
                // 値上がり銘柄数
                StatCard(
                    title: "値上がり",
                    value: "\(viewModel.allHoldings.filter { $0.isProfit }.count)",
                    icon: "arrow.up.circle.fill",
                    color: .green
                )

                // 値下がり銘柄数
                StatCard(
                    title: "値下がり",
                    value: "\(viewModel.allHoldings.filter { !$0.isProfit }.count)",
                    icon: "arrow.down.circle.fill",
                    color: .red
                )

                // API残り
                StatCard(
                    title: "API残り",
                    value: "\(viewModel.remainingAPIRequests)",
                    icon: "network",
                    color: AsaColors.mutedSage
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AsaColors.darkSlate)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Portfolio Summary Section

struct PortfolioSummarySection: View {
    let viewModel: PortfolioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ポートフォリオ")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            ForEach(viewModel.portfolios) { portfolio in
                PortfolioSummaryRow(portfolio: portfolio, viewModel: viewModel)
            }
        }
    }
}

struct PortfolioSummaryRow: View {
    let portfolio: Portfolio
    let viewModel: PortfolioViewModel

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: portfolio.colorHex))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(portfolio.name)
                    .font(.subheadline.bold())

                Text("\(portfolio.holdingsCount)銘柄")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(portfolio.totalValue.formattedCurrency)
                    .font(.subheadline.bold())

                HStack(spacing: 2) {
                    Image(systemName: portfolio.isProfit ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(portfolio.gainPercentage.formattedPercentage)
                        .font(.caption)
                }
                .foregroundStyle(portfolio.isProfit ? .green : .red)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Top Holdings Section

struct TopHoldingsSection: View {
    let viewModel: PortfolioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("保有額上位")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            ForEach(viewModel.topHoldings) { holding in
                HoldingSummaryRow(holding: holding)
            }
        }
    }
}

struct HoldingSummaryRow: View {
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
                Text(holding.marketValue.formattedCurrency)
                    .font(.subheadline.bold())

                HStack(spacing: 2) {
                    Image(systemName: holding.isProfit ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(holding.gainPercentage.formattedPercentage)
                        .font(.caption)
                }
                .foregroundStyle(holding.isProfit ? .green : .red)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    DashboardView(viewModel: PortfolioViewModel(
        stockAPIService: MockStockAPIService(),
        dataService: PortfolioDataService(modelContext: try! ModelContext(ModelContainer(for: Portfolio.self)))
    ))
}
