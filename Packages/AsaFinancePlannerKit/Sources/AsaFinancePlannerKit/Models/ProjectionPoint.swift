import Foundation

// MARK: - ProjectionPoint

/// 将来予測の年次データポイント
public struct ProjectionPoint: Identifiable, Sendable {
    public var id: Int { year }
    public let year: Int
    public let nominalValue: Decimal
    public let realValue: Decimal
    public let contributionTotal: Decimal

    public init(
        year: Int,
        nominalValue: Decimal,
        realValue: Decimal,
        contributionTotal: Decimal
    ) {
        self.year = year
        self.nominalValue = nominalValue
        self.realValue = realValue
        self.contributionTotal = contributionTotal
    }
}
