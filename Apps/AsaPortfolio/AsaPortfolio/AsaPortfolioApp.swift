import SwiftUI
import SwiftData

/// AsaPortfolio - 投資ポートフォリオ管理アプリ
/// 朝活時間に家族の資産状況をサクッとチェックできるアプリ
@main
struct AsaPortfolioApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Portfolio.self,
            Holding.self,
            Transaction.self,
            Dividend.self,
            WatchlistItem.self
        ])
    }
}
