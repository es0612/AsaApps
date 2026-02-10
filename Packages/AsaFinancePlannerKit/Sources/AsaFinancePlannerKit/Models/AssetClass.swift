import Foundation

// MARK: - AssetClass

/// 資産クラスの分類
public enum AssetClass: String, CaseIterable, Codable, Sendable {
    case domesticStock = "domestic_stock"
    case internationalStock = "international_stock"
    case domesticBond = "domestic_bond"
    case internationalBond = "international_bond"
    case reit = "reit"
    case cash = "cash"
    case commodity = "commodity"
    case crypto = "crypto"
    case insurance = "insurance"
    case other = "other"

    public var displayName: String {
        switch self {
        case .domesticStock: return "国内株式"
        case .internationalStock: return "海外株式"
        case .domesticBond: return "国内債券"
        case .internationalBond: return "海外債券"
        case .reit: return "REIT"
        case .cash: return "現金・預金"
        case .commodity: return "金・コモディティ"
        case .crypto: return "暗号資産"
        case .insurance: return "保険"
        case .other: return "その他"
        }
    }

    public var iconName: String {
        switch self {
        case .domesticStock: return "chart.bar.fill"
        case .internationalStock: return "globe"
        case .domesticBond: return "doc.text.fill"
        case .internationalBond: return "doc.text"
        case .reit: return "building.2.fill"
        case .cash: return "banknote.fill"
        case .commodity: return "diamond.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .insurance: return "umbrella.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    public var colorHex: String {
        switch self {
        case .domesticStock: return "#E74C3C"
        case .internationalStock: return "#3498DB"
        case .domesticBond: return "#2ECC71"
        case .internationalBond: return "#1ABC9C"
        case .reit: return "#9B59B6"
        case .cash: return "#F1C40F"
        case .commodity: return "#E67E22"
        case .crypto: return "#F39C12"
        case .insurance: return "#34495E"
        case .other: return "#95A5A6"
        }
    }

    /// デフォルト期待リターン率（年率）
    public var defaultExpectedReturn: Decimal {
        switch self {
        case .domesticStock: return Decimal(string: "0.05")!
        case .internationalStock: return Decimal(string: "0.07")!
        case .domesticBond: return Decimal(string: "0.01")!
        case .internationalBond: return Decimal(string: "0.03")!
        case .reit: return Decimal(string: "0.04")!
        case .cash: return Decimal(string: "0.001")!
        case .commodity: return Decimal(string: "0.03")!
        case .crypto: return Decimal(string: "0.10")!
        case .insurance: return Decimal(string: "0.01")!
        case .other: return Decimal(string: "0.02")!
        }
    }

    /// デフォルトリスク値（標準偏差、年率）
    public var defaultRisk: Decimal {
        switch self {
        case .domesticStock: return Decimal(string: "0.20")!
        case .internationalStock: return Decimal(string: "0.22")!
        case .domesticBond: return Decimal(string: "0.03")!
        case .internationalBond: return Decimal(string: "0.10")!
        case .reit: return Decimal(string: "0.15")!
        case .cash: return Decimal(string: "0.001")!
        case .commodity: return Decimal(string: "0.18")!
        case .crypto: return Decimal(string: "0.50")!
        case .insurance: return Decimal(string: "0.02")!
        case .other: return Decimal(string: "0.10")!
        }
    }
}
