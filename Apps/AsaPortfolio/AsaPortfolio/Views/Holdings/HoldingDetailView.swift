import SwiftUI
import SwiftData
import AsaUIKit

/// 保有資産詳細ビュー
struct HoldingDetailView: View {
    @Bindable var viewModel: PortfolioViewModel
    let holding: Holding
    @Environment(\.dismiss) private var dismiss

    @State private var showAddTransaction = false

    var body: some View {
        NavigationStack {
            List {
                // 価格情報セクション
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(holding.symbol)
                                        .font(.title.bold())

                                    Text(holding.assetType.displayName)
                                        .font(.caption)
                                        .foregroundStyle(AsaColors.coffeeBrown)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AsaColors.coffeeBrown.opacity(0.1))
                                        .clipShape(Capsule())
                                }

                                Text(holding.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                        // 現在価格
                        HStack(alignment: .bottom) {
                            Text(holding.currentPrice.formattedPrice)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(AsaColors.coffeeBrown)

                            Text(holding.currency)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 4)
                        }

                        // 更新時刻
                        Text("最終更新: \(holding.lastUpdated, style: .relative)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                }

                // 保有情報セクション
                Section("保有情報") {
                    DetailRow(title: "保有数量", value: CurrencyFormatter.formatQuantity(holding.quantity))
                    DetailRow(title: "平均取得価格", value: holding.averageCost.formattedPrice)
                    DetailRow(title: "取得原価", value: holding.totalCost.formattedCurrency)
                    DetailRow(title: "時価評価額", value: holding.marketValue.formattedCurrency)
                }

                // 損益情報セクション
                Section("損益") {
                    DetailRow(
                        title: "含み損益",
                        value: holding.unrealizedGain.formattedCurrency,
                        valueColor: holding.isProfit ? .green : .red
                    )
                    DetailRow(
                        title: "損益率",
                        value: holding.gainPercentage.formattedPercentage,
                        valueColor: holding.isProfit ? .green : .red
                    )
                }

                // 配当情報セクション
                if !holding.dividends.isEmpty {
                    Section("配当") {
                        DetailRow(title: "配当金合計", value: holding.totalDividends.formattedCurrency)
                        DetailRow(title: "配当受取回数", value: "\(holding.dividends.count)回")
                    }
                }

                // 追加情報セクション
                Section("詳細") {
                    if let sector = holding.sectorName {
                        DetailRow(title: "セクター", value: sector)
                    }
                    if let exchange = holding.exchange {
                        DetailRow(title: "取引所", value: exchange)
                    }
                    DetailRow(title: "通貨", value: holding.currency)
                }

                // 取引履歴セクション
                Section("取引履歴 (\(holding.transactions.count))") {
                    if holding.transactions.isEmpty {
                        HStack {
                            Spacer()
                            Text("取引履歴がありません")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(holding.transactions.sorted { $0.executedAt > $1.executedAt }.prefix(5)) { transaction in
                            TransactionRow(transaction: transaction)
                        }

                        if holding.transactions.count > 5 {
                            NavigationLink {
                                TransactionListView(holding: holding)
                            } label: {
                                Text("すべての取引を表示")
                                    .foregroundStyle(AsaColors.coffeeBrown)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("銘柄詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionSheet(viewModel: viewModel, holding: holding)
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = AsaColors.darkSlate

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            Image(systemName: transaction.transactionType.icon)
                .foregroundStyle(Color(transaction.transactionType.color))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.transactionType.displayName)
                    .font(.subheadline.bold())

                Text(transaction.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.formattedAmount)
                    .font(.subheadline.bold())

                Text("\(CurrencyFormatter.formatQuantity(transaction.quantity))株 × \(transaction.pricePerShare.formattedPrice)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Transaction List View

struct TransactionListView: View {
    let holding: Holding

    var body: some View {
        List {
            ForEach(holding.transactions.sorted { $0.executedAt > $1.executedAt }) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("取引履歴")
    }
}

// MARK: - Add Transaction Sheet

struct AddTransactionSheet: View {
    @Bindable var viewModel: PortfolioViewModel
    let holding: Holding
    @Environment(\.dismiss) private var dismiss

    @State private var transactionType: TransactionType = .buy
    @State private var quantityText = ""
    @State private var priceText = ""
    @State private var feesText = "0"
    @State private var executedAt = Date()
    @State private var note = ""

    @State private var isAdding = false
    @State private var errorMessage: String?

    private var quantity: Decimal? {
        Decimal(string: quantityText)
    }

    private var price: Decimal? {
        Decimal(string: priceText)
    }

    private var fees: Decimal {
        Decimal(string: feesText) ?? 0
    }

    private var isValid: Bool {
        quantity != nil && price != nil && quantity! > 0 && price! > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("取引タイプ") {
                    Picker("タイプ", selection: $transactionType) {
                        ForEach([TransactionType.buy, .sell, .dividend], id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("取引内容") {
                    HStack {
                        Text("数量")
                        Spacer()
                        TextField("0", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    HStack {
                        Text("単価")
                        Spacer()
                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    HStack {
                        Text("手数料")
                        Spacer()
                        TextField("0", text: $feesText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    DatePicker("取引日", selection: $executedAt, displayedComponents: [.date, .hourAndMinute])
                }

                if let qty = quantity, let prc = price {
                    Section("合計") {
                        HStack {
                            Text("取引金額")
                            Spacer()
                            Text(CurrencyFormatter.format(qty * prc + fees, currencyCode: holding.currency))
                                .bold()
                                .foregroundStyle(AsaColors.coffeeBrown)
                        }
                    }
                }

                Section("メモ（任意）") {
                    TextField("メモを入力", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("取引を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addTransaction()
                    }
                    .disabled(!isValid || isAdding)
                }
            }
        }
    }

    private func addTransaction() {
        guard let qty = quantity, let prc = price else { return }

        isAdding = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.addTransaction(
                    to: holding,
                    type: transactionType,
                    quantity: qty,
                    pricePerShare: prc,
                    fees: fees,
                    executedAt: executedAt,
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
    let container = try! ModelContainer(for: Portfolio.self, Holding.self)
    let context = ModelContext(container)
    let holding = Holding(
        symbol: "AAPL",
        name: "Apple Inc.",
        assetType: .stock,
        quantity: 10,
        averageCost: 150,
        currentPrice: 180
    )
    context.insert(holding)

    return HoldingDetailView(
        viewModel: PortfolioViewModel(
            stockAPIService: MockStockAPIService(),
            dataService: PortfolioDataService(modelContext: context)
        ),
        holding: holding
    )
}
