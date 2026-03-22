import SwiftUI
import SwiftData
import AsaUIKit

/// ポートフォリオ一覧ビュー
struct PortfolioListView: View {
    @Bindable var viewModel: PortfolioViewModel
    @State private var showAddPortfolio = false
    @State private var selectedPortfolioForDetail: Portfolio?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.portfolios.isEmpty {
                    EmptyPortfolioView(showAddPortfolio: $showAddPortfolio)
                } else {
                    portfolioList
                }
            }
            .navigationTitle("ポートフォリオ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddPortfolio = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddPortfolio) {
                AddPortfolioSheet(viewModel: viewModel)
            }
            .sheet(item: $selectedPortfolioForDetail) { portfolio in
                PortfolioDetailView(viewModel: viewModel, portfolio: portfolio)
            }
        }
    }

    private var portfolioList: some View {
        List {
            ForEach(viewModel.portfolios) { portfolio in
                PortfolioRow(portfolio: portfolio)
                    .onTapGesture {
                        selectedPortfolioForDetail = portfolio
                    }
            }
            .onDelete(perform: deletePortfolio)
        }
        .listStyle(.insetGrouped)
    }

    private func deletePortfolio(at offsets: IndexSet) {
        for index in offsets {
            let portfolio = viewModel.portfolios[index]
            Task {
                try? await viewModel.deletePortfolio(portfolio)
            }
        }
    }
}

// MARK: - Portfolio Row

struct PortfolioRow: View {
    let portfolio: Portfolio

    var body: some View {
        HStack(spacing: 16) {
            // カラーインジケーター
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: portfolio.colorHex))
                .frame(width: 8, height: 60)

            VStack(alignment: .leading, spacing: 8) {
                // ポートフォリオ名と銘柄数
                HStack {
                    Text(portfolio.name)
                        .font(.headline)

                    Spacer()

                    Text("\(portfolio.holdingsCount)銘柄")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AsaColors.darkSlate.opacity(0.1))
                        .clipShape(Capsule())
                }

                // 時価総額と損益
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("時価総額")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(portfolio.totalValue.formattedCurrency)
                            .font(.subheadline.bold())
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("含み損益")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Text(portfolio.totalGain.formattedCurrency)
                                .font(.subheadline.bold())

                            Text("(\(portfolio.gainPercentage.formattedPercentage))")
                                .font(.caption)
                        }
                        .foregroundStyle(portfolio.isProfit ? .green : .red)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Empty State

struct EmptyPortfolioView: View {
    @Binding var showAddPortfolio: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "briefcase")
                .font(.system(size: 60))
                .foregroundStyle(AsaColors.mutedSage)

            Text("ポートフォリオがありません")
                .font(.title2.bold())
                .foregroundStyle(AsaColors.darkSlate)

            Text("最初のポートフォリオを作成して\n資産管理を始めましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddPortfolio = true
            } label: {
                Label("ポートフォリオを作成", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AsaColors.coffeeBrown)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

// MARK: - Add Portfolio Sheet

struct AddPortfolioSheet: View {
    @Bindable var viewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var note = ""
    @State private var selectedColor = "#C68C53"
    @State private var isCreating = false
    @State private var errorMessage: String?

    private let colorOptions = [
        "#C68C53", // AsaCoffeeBrown
        "#8B5A2B", // AsaMocha
        "#2F3E46", // AsaDarkSlate
        "#7A918D", // AsaMutedSage
        "#E8D5B9", // AsaSoftCream
        "#4A90D9", // Blue
        "#50C878", // Green
        "#FF6B6B", // Red
        "#9B59B6", // Purple
        "#F39C12"  // Orange
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("ポートフォリオ名", text: $name)

                    TextField("メモ（任意）", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("カラー") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.headline.bold())
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("ポートフォリオを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        createPortfolio()
                    }
                    .disabled(name.isEmpty || isCreating)
                }
            }
        }
    }

    private func createPortfolio() {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.createPortfolio(
                    name: name,
                    note: note,
                    colorHex: selectedColor
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isCreating = false
            }
        }
    }
}

// MARK: - Portfolio Detail View

struct PortfolioDetailView: View {
    @Bindable var viewModel: PortfolioViewModel
    let portfolio: Portfolio
    @Environment(\.dismiss) private var dismiss
    @State private var showAddHolding = false
    @State private var selectedHolding: Holding?

    var body: some View {
        NavigationStack {
            List {
                // サマリーセクション
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(Color(hex: portfolio.colorHex))
                                .frame(width: 16, height: 16)

                            Text(portfolio.name)
                                .font(.title2.bold())
                        }

                        if !portfolio.note.isEmpty {
                            Text(portfolio.note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading) {
                                Text("時価総額")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(portfolio.totalValue.formattedCurrency)
                                    .font(.title3.bold())
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("含み損益")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(portfolio.totalGain.formattedCurrency)
                                    .font(.title3.bold())
                                    .foregroundStyle(portfolio.isProfit ? .green : .red)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // 保有銘柄セクション
                Section("保有銘柄 (\(portfolio.holdings.count))") {
                    if portfolio.holdings.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.largeTitle)
                                    .foregroundStyle(AsaColors.mutedSage)
                                Text("銘柄がありません")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                    } else {
                        ForEach(portfolio.holdings.sorted { $0.marketValue > $1.marketValue }) { holding in
                            HoldingRow(holding: holding)
                                .onTapGesture {
                                    selectedHolding = holding
                                }
                        }
                        .onDelete(perform: deleteHolding)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddHolding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddHolding) {
                AddHoldingSheet(viewModel: viewModel, portfolio: portfolio)
            }
            .sheet(item: $selectedHolding) { holding in
                HoldingDetailView(viewModel: viewModel, holding: holding)
            }
        }
    }

    private func deleteHolding(at offsets: IndexSet) {
        let sortedHoldings = portfolio.holdings.sorted { $0.marketValue > $1.marketValue }
        for index in offsets {
            let holding = sortedHoldings[index]
            Task {
                try? await viewModel.deleteHolding(holding)
            }
        }
    }
}

// MARK: - Holding Row

struct HoldingRow: View {
    let holding: Holding

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(holding.symbol)
                        .font(.headline)

                    Text(holding.assetType.displayName)
                        .font(.caption2)
                        .foregroundStyle(AsaColors.coffeeBrown)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AsaColors.coffeeBrown.opacity(0.1))
                        .clipShape(Capsule())
                }

                Text(holding.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(CurrencyFormatter.formatQuantity(holding.quantity))株 × \(holding.currentPrice.formattedPrice)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(holding.marketValue.formattedCurrency)
                    .font(.subheadline.bold())

                HStack(spacing: 2) {
                    Image(systemName: holding.isProfit ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(holding.unrealizedGain.formattedCurrency)
                        .font(.caption)
                }
                .foregroundStyle(holding.isProfit ? .green : .red)

                Text(holding.gainPercentage.formattedPercentage)
                    .font(.caption2)
                    .foregroundStyle(holding.isProfit ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PortfolioListView(viewModel: PortfolioViewModel(
        stockAPIService: MockStockAPIService(),
        dataService: PortfolioDataService(modelContext: try! ModelContext(ModelContainer(for: Portfolio.self)))
    ))
}
