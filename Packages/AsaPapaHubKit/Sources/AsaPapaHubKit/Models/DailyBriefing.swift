import Foundation
import SwiftData

// MARK: - デイリーブリーフィング

@Model
public final class DailyBriefing {
    public var id: UUID
    public var date: Date
    public var greeting: String
    public var scheduleOverview: String
    public var healthAdvice: String
    public var motivationalMessage: String
    public var statusRawValue: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        greeting: String = "",
        scheduleOverview: String = "",
        healthAdvice: String = "",
        motivationalMessage: String = "",
        statusRawValue: String = BriefingStatus.pending.rawValue,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.greeting = greeting
        self.scheduleOverview = scheduleOverview
        self.healthAdvice = healthAdvice
        self.motivationalMessage = motivationalMessage
        self.statusRawValue = statusRawValue
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    public var status: BriefingStatus {
        get { BriefingStatus(rawValue: statusRawValue) ?? .pending }
        set { statusRawValue = newValue.rawValue }
    }
}
