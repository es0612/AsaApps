import Foundation

// MARK: - InsightType

/// インサイトの種類
public enum InsightType: String, Codable, Sendable {
    case warning
    case suggestion
    case achievement
    case info
}

// MARK: - InsightPriority

/// インサイトの優先度
public enum InsightPriority: Int, Comparable, Codable, Sendable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3

    public static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - FinancialInsight

/// 金融アドバイス・インサイトデータ
public struct FinancialInsight: Identifiable, Sendable {
    public var id: UUID = UUID()
    public let type: InsightType
    public let priority: InsightPriority
    public let title: String
    public let message: String
    public let iconName: String
    public let createdAt: Date

    public init(
        type: InsightType,
        priority: InsightPriority,
        title: String,
        message: String,
        iconName: String,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.type = type
        self.priority = priority
        self.title = title
        self.message = message
        self.iconName = iconName
        self.createdAt = createdAt
    }
}
