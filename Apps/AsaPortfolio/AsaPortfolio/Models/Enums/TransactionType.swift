import Foundation

/// 取引タイプ - 買い、売り、配当など
enum TransactionType: String, Codable, CaseIterable, Sendable {
    case buy = "buy"
    case sell = "sell"
    case dividend = "dividend"
    case split = "split"
    case transfer = "transfer"

    var displayName: String {
        switch self {
        case .buy: return "購入"
        case .sell: return "売却"
        case .dividend: return "配当"
        case .split: return "分割"
        case .transfer: return "移管"
        }
    }

    var icon: String {
        switch self {
        case .buy: return "arrow.down.circle.fill"
        case .sell: return "arrow.up.circle.fill"
        case .dividend: return "dollarsign.circle.fill"
        case .split: return "arrow.triangle.branch"
        case .transfer: return "arrow.left.arrow.right"
        }
    }

    var color: String {
        switch self {
        case .buy: return "AsaCoffeeBrown"
        case .sell: return "AsaMutedSage"
        case .dividend: return "green"
        case .split: return "AsaDarkSlate"
        case .transfer: return "AsaMocha"
        }
    }
}
