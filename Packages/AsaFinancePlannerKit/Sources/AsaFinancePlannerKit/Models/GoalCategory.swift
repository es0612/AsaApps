import Foundation

// MARK: - GoalCategory

/// 金融目標のカテゴリ分類
public enum GoalCategory: String, CaseIterable, Codable, Sendable {
    case retirement = "retirement"
    case education = "education"
    case housing = "housing"
    case emergency = "emergency"
    case travel = "travel"
    case vehicle = "vehicle"
    case investment = "investment"
    case other = "other"

    public var displayName: String {
        switch self {
        case .retirement: return "退職・老後"
        case .education: return "教育費"
        case .housing: return "住宅購入"
        case .emergency: return "緊急資金"
        case .travel: return "旅行"
        case .vehicle: return "車両購入"
        case .investment: return "投資目標"
        case .other: return "その他"
        }
    }

    public var iconName: String {
        switch self {
        case .retirement: return "figure.walk"
        case .education: return "graduationcap.fill"
        case .housing: return "house.fill"
        case .emergency: return "shield.fill"
        case .travel: return "airplane"
        case .vehicle: return "car.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "star.fill"
        }
    }

    public var colorHex: String {
        switch self {
        case .retirement: return "#FF6B6B"
        case .education: return "#4ECDC4"
        case .housing: return "#45B7D1"
        case .emergency: return "#FFA07A"
        case .travel: return "#98D8C8"
        case .vehicle: return "#7C8CF8"
        case .investment: return "#F7DC6F"
        case .other: return "#B0BEC5"
        }
    }
}
