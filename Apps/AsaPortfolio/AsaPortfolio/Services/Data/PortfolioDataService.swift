import Foundation
import SwiftData

/// ポートフォリオデータサービス - SwiftData CRUD操作
@MainActor
final class PortfolioDataService {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Portfolio CRUD

    func fetchAllPortfolios() throws -> [Portfolio] {
        let descriptor = FetchDescriptor<Portfolio>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchPortfolio(by id: UUID) throws -> Portfolio? {
        let descriptor = FetchDescriptor<Portfolio>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func createPortfolio(
        name: String,
        note: String = "",
        colorHex: String = "#C68C53"
    ) throws -> Portfolio {
        let portfolios = try fetchAllPortfolios()
        let maxSortOrder = portfolios.map(\.sortOrder).max() ?? -1

        let portfolio = Portfolio(
            name: name,
            note: note,
            colorHex: colorHex,
            sortOrder: maxSortOrder + 1
        )

        modelContext.insert(portfolio)
        try modelContext.save()

        return portfolio
    }

    func updatePortfolio(_ portfolio: Portfolio) throws {
        try modelContext.save()
    }

    func deletePortfolio(_ portfolio: Portfolio) throws {
        modelContext.delete(portfolio)
        try modelContext.save()
    }

    // MARK: - Holding CRUD

    func fetchAllHoldings() throws -> [Holding] {
        let descriptor = FetchDescriptor<Holding>(
            sortBy: [SortDescriptor(\.symbol)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchHoldings(for portfolio: Portfolio) throws -> [Holding] {
        let portfolioId = portfolio.id
        let descriptor = FetchDescriptor<Holding>(
            predicate: #Predicate { $0.portfolio?.id == portfolioId },
            sortBy: [SortDescriptor(\.symbol)]
        )
        return try modelContext.fetch(descriptor)
    }

    func addHolding(
        to portfolio: Portfolio,
        symbol: String,
        name: String,
        assetType: AssetType,
        quantity: Decimal,
        averageCost: Decimal,
        currentPrice: Decimal = 0,
        currency: String = "USD",
        sectorName: String? = nil
    ) throws -> Holding {
        let holding = Holding(
            symbol: symbol,
            name: name,
            assetType: assetType,
            quantity: quantity,
            averageCost: averageCost,
            currentPrice: currentPrice,
            currency: currency,
            sectorName: sectorName
        )

        holding.portfolio = portfolio
        modelContext.insert(holding)
        try modelContext.save()

        return holding
    }

    func updateHolding(_ holding: Holding) throws {
        try modelContext.save()
    }

    func updateHoldingPrice(_ holding: Holding, price: Decimal) throws {
        holding.currentPrice = price
        holding.lastUpdated = Date()
        try modelContext.save()
    }

    func deleteHolding(_ holding: Holding) throws {
        modelContext.delete(holding)
        try modelContext.save()
    }

    // MARK: - Transaction CRUD

    func fetchTransactions(for holding: Holding) throws -> [Transaction] {
        let holdingId = holding.id
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.holding?.id == holdingId },
            sortBy: [SortDescriptor(\.executedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func addTransaction(
        to holding: Holding,
        type: TransactionType,
        quantity: Decimal,
        pricePerShare: Decimal,
        fees: Decimal = 0,
        executedAt: Date = Date(),
        note: String? = nil
    ) throws -> Transaction {
        let transaction = Transaction(
            transactionType: type,
            quantity: quantity,
            pricePerShare: pricePerShare,
            fees: fees,
            executedAt: executedAt,
            note: note
        )

        transaction.holding = holding
        modelContext.insert(transaction)

        // 取引に応じて保有数量と平均取得価格を更新
        updateHoldingFromTransaction(holding, transaction: transaction)

        try modelContext.save()
        return transaction
    }

    func deleteTransaction(_ transaction: Transaction) throws {
        modelContext.delete(transaction)
        try modelContext.save()
    }

    // MARK: - Dividend CRUD

    func fetchDividends(for holding: Holding) throws -> [Dividend] {
        let holdingId = holding.id
        let descriptor = FetchDescriptor<Dividend>(
            predicate: #Predicate { $0.holding?.id == holdingId },
            sortBy: [SortDescriptor(\.paymentDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchUpcomingDividends() throws -> [Dividend] {
        let now = Date()
        let descriptor = FetchDescriptor<Dividend>(
            predicate: #Predicate { $0.paymentDate > now },
            sortBy: [SortDescriptor(\.paymentDate)]
        )
        return try modelContext.fetch(descriptor)
    }

    func addDividend(
        to holding: Holding,
        amount: Decimal,
        perShare: Decimal,
        exDividendDate: Date,
        paymentDate: Date,
        isReinvested: Bool = false,
        note: String? = nil
    ) throws -> Dividend {
        let dividend = Dividend(
            amount: amount,
            perShare: perShare,
            sharesOwned: holding.quantity,
            exDividendDate: exDividendDate,
            paymentDate: paymentDate,
            currency: holding.currency,
            isReinvested: isReinvested,
            note: note
        )

        dividend.holding = holding
        modelContext.insert(dividend)
        try modelContext.save()

        return dividend
    }

    func deleteDividend(_ dividend: Dividend) throws {
        modelContext.delete(dividend)
        try modelContext.save()
    }

    // MARK: - Watchlist CRUD

    func fetchWatchlist() throws -> [WatchlistItem] {
        let descriptor = FetchDescriptor<WatchlistItem>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func addToWatchlist(
        symbol: String,
        name: String,
        assetType: AssetType = .stock,
        currentPrice: Decimal = 0,
        previousClose: Decimal = 0,
        targetPrice: Decimal? = nil,
        note: String? = nil
    ) throws -> WatchlistItem {
        let item = WatchlistItem(
            symbol: symbol,
            name: name,
            assetType: assetType,
            currentPrice: currentPrice,
            previousClose: previousClose,
            targetPrice: targetPrice,
            note: note
        )

        modelContext.insert(item)
        try modelContext.save()

        return item
    }

    func updateWatchlistItem(_ item: WatchlistItem) throws {
        try modelContext.save()
    }

    func removeFromWatchlist(_ item: WatchlistItem) throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    // MARK: - Private Helpers

    private func updateHoldingFromTransaction(_ holding: Holding, transaction: Transaction) {
        switch transaction.transactionType {
        case .buy:
            // 平均取得価格を再計算
            let currentTotalCost = holding.quantity * holding.averageCost
            let newTotalCost = transaction.quantity * transaction.pricePerShare + transaction.fees
            let newQuantity = holding.quantity + transaction.quantity

            if newQuantity > 0 {
                holding.averageCost = (currentTotalCost + newTotalCost) / newQuantity
                holding.quantity = newQuantity
            }

        case .sell:
            holding.quantity = max(0, holding.quantity - transaction.quantity)

        case .dividend:
            // 配当は数量に影響しない
            break

        case .split:
            // 株式分割の処理（将来実装）
            break

        case .transfer:
            // 移管の処理（将来実装）
            break
        }
    }
}
