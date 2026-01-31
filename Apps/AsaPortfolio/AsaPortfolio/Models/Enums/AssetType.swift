import Foundation

/// 資産タイプ - 株式、ETF、投資信託など
enum AssetType: String, Codable, CaseIterable, Sendable {
    case stock = "stock"
    case etf = "etf"
    case mutualFund = "mutual_fund"
    case bond = "bond"
    case crypto = "crypto"
    case other = "other"

    var displayName: String {
        switch self {
        case .stock: return "株式"
        case .etf: return "ETF"
        case .mutualFund: return "投資信託"
        case .bond: return "債券"
        case .crypto: return "暗号資産"
        case .other: return "その他"
        }
    }

    var icon: String {
        switch self {
        case .stock: return "chart.line.uptrend.xyaxis"
        case .etf: return "chart.pie"
        case .mutualFund: return "building.columns"
        case .bond: return "doc.text"
        case .crypto: return "bitcoinsign.circle"
        case .other: return "questionmark.circle"
        }
    }
}
