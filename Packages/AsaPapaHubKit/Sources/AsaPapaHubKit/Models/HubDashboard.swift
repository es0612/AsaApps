import Foundation
import SwiftData

// MARK: - ハブダッシュボード

@Model
public final class HubDashboard {
    public var id: UUID
    public var date: Date
    public var morningScore: Int
    public var stepsCount: Int
    public var sleepHours: Double
    public var moodRawValue: String?
    public var overallProgress: Double
    public var activeDomainsRawValue: String
    public var briefingSummary: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        morningScore: Int = 0,
        stepsCount: Int = 0,
        sleepHours: Double = 0.0,
        moodRawValue: String? = nil,
        overallProgress: Double = 0.0,
        activeDomainsRawValue: String = "",
        briefingSummary: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.morningScore = morningScore
        self.stepsCount = stepsCount
        self.sleepHours = sleepHours
        self.moodRawValue = moodRawValue
        self.overallProgress = overallProgress
        self.activeDomainsRawValue = activeDomainsRawValue
        self.briefingSummary = briefingSummary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    public var activeDomains: [LifeDomain] {
        get {
            guard !activeDomainsRawValue.isEmpty else { return [] }
            return activeDomainsRawValue.split(separator: ",")
                .compactMap { LifeDomain(rawValue: String($0)) }
        }
        set {
            activeDomainsRawValue = newValue.map(\.rawValue).joined(separator: ",")
        }
    }
}
