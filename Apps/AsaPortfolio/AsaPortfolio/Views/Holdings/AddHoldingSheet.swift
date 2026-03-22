import SwiftUI
import SwiftData
import AsaUIKit

/// 保有資産追加シート
struct AddHoldingSheet: View {
    @Bindable var viewModel: PortfolioViewModel
    let portfolio: Portfolio
    @Environment(\.dismiss) private var dismiss

    @State private var symbol = ""
    @State private var name = ""
    @State private var assetType: AssetType = .stock
    @State private var quantityText = ""
    @State private var averageCostText = ""
    @State private var currency = "USD"
    @State private var sectorName = ""

    @State private var searchResults: [SymbolSearchResult] = []
    @State private var isSearching = false
    @State private var isAdding = false
    @State private var errorMessage: String?
    @State private var showSearchResults = false

    private var quantity: Decimal? {
        Decimal(string: quantityText)
    }

    private var averageCost: Decimal? {
        Decimal(string: averageCostText)
    }

    private var isValid: Bool {
        !symbol.isEmpty && !name.isEmpty && quantity != nil && averageCost != nil && quantity! > 0 && averageCost! > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // 銘柄検索セクション
                Section("銘柄検索") {
                    HStack {
                        TextField("ティッカーシンボル（例: AAPL）", text: $symbol)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: symbol) { _, newValue in
                                if newValue.count >= 1 {
                                    searchSymbols()
                                } else {
                                    searchResults = []
                                }
                            }

                        if isSearching {
                            ProgressView()
                        }
                    }

                    if !searchResults.isEmpty && showSearchResults {
                        ForEach(searchResults.prefix(5)) { result in
                            Button {
                                selectSearchResult(result)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(result.symbol)
                                            .font(.headline)
                                            .foregroundStyle(AsaColors.darkSlate)
                                        Text(result.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text(result.region)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }

                // 基本情報セクション
                Section("基本情報") {
                    TextField("銘柄名", text: $name)

                    Picker("資産タイプ", selection: $assetType) {
                        ForEach(AssetType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    Picker("通貨", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("JPY").tag("JPY")
                        Text("EUR").tag("EUR")
                    }

                    TextField("セクター（任意）", text: $sectorName)
                }

                // 取得情報セクション
                Section("取得情報") {
                    HStack {
                        Text("数量")
                        Spacer()
                        TextField("0", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    HStack {
                        Text("平均取得価格")
                        Spacer()
                        TextField("0.00", text: $averageCostText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    if let qty = quantity, let cost = averageCost, qty > 0, cost > 0 {
                        HStack {
                            Text("取得原価合計")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(CurrencyFormatter.format(qty * cost, currencyCode: currency))
                                .foregroundStyle(AsaColors.coffeeBrown)
                                .bold()
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("銘柄を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addHolding()
                    }
                    .disabled(!isValid || isAdding)
                }
            }
        }
    }

    private func searchSymbols() {
        guard symbol.count >= 1 else { return }

        isSearching = true
        showSearchResults = true

        Task {
            do {
                searchResults = try await viewModel.searchSymbols(keywords: symbol)
            } catch {
                // 検索エラーは無視（UIには表示しない）
            }
            isSearching = false
        }
    }

    private func selectSearchResult(_ result: SymbolSearchResult) {
        symbol = result.symbol
        name = result.name
        currency = result.currency
        showSearchResults = false
    }

    private func addHolding() {
        guard let qty = quantity, let cost = averageCost else { return }

        isAdding = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.addHolding(
                    to: portfolio,
                    symbol: symbol.uppercased(),
                    name: name,
                    assetType: assetType,
                    quantity: qty,
                    averageCost: cost,
                    currency: currency,
                    sectorName: sectorName.isEmpty ? nil : sectorName
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isAdding = false
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Portfolio.self)
    let context = ModelContext(container)
    let portfolio = Portfolio(name: "メインポートフォリオ")
    context.insert(portfolio)

    return AddHoldingSheet(
        viewModel: PortfolioViewModel(
            stockAPIService: MockStockAPIService(),
            dataService: PortfolioDataService(modelContext: context)
        ),
        portfolio: portfolio
    )
}
