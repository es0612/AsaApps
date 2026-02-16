import Foundation
import SwiftData

// MARK: - ドメインスナップショット

@Model
public final class DomainSnapshot {
    public var id: UUID
    public var date: Date
    public var domainRawValue: String
    public var score: Int
    public var summary: String
    public var trendRawValue: String
    public var detailJSON: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        domainRawValue: String = LifeDomain.morning.rawValue,
        score: Int = 0,
        summary: String = "",
        trendRawValue: String = TrendDirection.stable.rawValue,
        detailJSON: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.domainRawValue = domainRawValue
        self.score = score
        self.summary = summary
        self.trendRawValue = trendRawValue
        self.detailJSON = detailJSON
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    public var domain: LifeDomain {
        get { LifeDomain(rawValue: domainRawValue) ?? .morning }
        set { domainRawValue = newValue.rawValue }
    }

    public var trend: TrendDirection {
        get { TrendDirection(rawValue: trendRawValue) ?? .stable }
        set { trendRawValue = newValue.rawValue }
    }
}
