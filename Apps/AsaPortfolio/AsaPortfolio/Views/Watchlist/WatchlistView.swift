import SwiftUI
import SwiftData

/// ウォッチリストビュー
struct WatchlistView: View {
    @Bindable var viewModel: PortfolioViewModel
    @State private var showAddWatchlist = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.watchlistItems.isEmpty {
                    EmptyWatchlistView(showAddWatchlist: $showAddWatchlist)
                } else {
                    watchlistContent
                }
            }
            .navigationTitle("ウォッチリスト")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddWatchlist = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
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
            .sheet(isPresented: $showAddWatchlist) {
                AddWatchlistSheet(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.refreshQuotes()
            }
        }
    }

    private var watchlistContent: some View {
        List {
            ForEach(viewModel.watchlistItems) { item in
                WatchlistItemRow(item: item)
            }
            .onDelete(perform: deleteItem)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            let item = viewModel.watchlistItems[index]
            Task {
                try? await viewModel.removeFromWatchlist(item)
            }
        }
    }
}

// MARK: - Watchlist Item Row

struct WatchlistItemRow: View {
    let item: WatchlistItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.symbol)
                        .font(.headline)

                    Text(item.assetType.displayName)
                        .font(.caption2)
                        .foregroundStyle(Color("AsaCoffeeBrown"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color("AsaCoffeeBrown").opacity(0.1))
                        .clipShape(Capsule())
                }

                Text(item.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let target = item.targetPrice {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.caption2)
                        Text("目標: \(target.formattedPrice)")
                            .font(.caption2)
                    }
                    .foregroundStyle(item.targetReached ? .green : Color("AsaMutedSage"))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(item.currentPrice.formattedPrice)
                    .font(.subheadline.bold())

                HStack(spacing: 2) {
                    Image(systemName: item.isUp ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(item.dailyChange.formattedPrice)
                        .font(.caption)
                }
                .foregroundStyle(item.isUp ? .green : .red)

                Text(item.dailyChangePercentage.formattedPercentage)
                    .font(.caption2)
                    .foregroundStyle(item.isUp ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State

struct EmptyWatchlistView: View {
    @Binding var showAddWatchlist: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star")
                .font(.system(size: 60))
                .foregroundStyle(Color("AsaMutedSage"))

            Text("ウォッチリストが空です")
                .font(.title2.bold())
                .foregroundStyle(Color("AsaDarkSlate"))

            Text("気になる銘柄を追加して\n価格動向をチェックしましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddWatchlist = true
            } label: {
                Label("銘柄を追加", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("AsaCoffeeBrown"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

// MARK: - Add Watchlist Sheet

struct AddWatchlistSheet: View {
    @Bindable var viewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var symbol = ""
    @State private var name = ""
    @State private var assetType: AssetType = .stock
    @State private var targetPriceText = ""
    @State private var note = ""

    @State private var searchResults: [SymbolSearchResult] = []
    @State private var isSearching = false
    @State private var isAdding = false
    @State private var errorMessage: String?
    @State private var showSearchResults = false

    private var targetPrice: Decimal? {
        Decimal(string: targetPriceText)
    }

    private var isValid: Bool {
        !symbol.isEmpty && !name.isEmpty
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
                                            .foregroundStyle(Color("AsaDarkSlate"))
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
                }

                // 目標価格セクション
                Section("目標価格（任意）") {
                    HStack {
                        TextField("目標価格", text: $targetPriceText)
                            .keyboardType(.decimalPad)

                        if targetPrice != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    TextField("メモ（任意）", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("ウォッチリストに追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addToWatchlist()
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
                // 検索エラーは無視
            }
            isSearching = false
        }
    }

    private func selectSearchResult(_ result: SymbolSearchResult) {
        symbol = result.symbol
        name = result.name
        showSearchResults = false
    }

    private func addToWatchlist() {
        isAdding = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.addToWatchlist(
                    symbol: symbol.uppercased(),
                    name: name,
                    assetType: assetType,
                    targetPrice: targetPrice,
                    note: note.isEmpty ? nil : note
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
    WatchlistView(viewModel: PortfolioViewModel(
        stockAPIService: MockStockAPIService(),
        dataService: PortfolioDataService(modelContext: try! ModelContext(ModelContainer(for: Portfolio.self)))
    ))
}
