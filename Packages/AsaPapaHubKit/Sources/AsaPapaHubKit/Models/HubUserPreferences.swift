import Foundation
import SwiftData

// MARK: - ユーザー設定

@Model
public final class HubUserPreferences {
    public var id: UUID
    public var wakeUpTime: Date
    public var enabledDomainsRawValue: String
    public var aiEnabled: Bool
    public var notificationsEnabled: Bool
    public var stepsGoal: Int
    public var sleepGoalHours: Double
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        wakeUpTime: Date = Calendar.current.date(from: DateComponents(hour: 5, minute: 30)) ?? Date(),
        enabledDomainsRawValue: String = LifeDomain.allCases.map(\.rawValue).joined(separator: ","),
        aiEnabled: Bool = true,
        notificationsEnabled: Bool = true,
        stepsGoal: Int = 10000,
        sleepGoalHours: Double = 7.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.wakeUpTime = wakeUpTime
        self.enabledDomainsRawValue = enabledDomainsRawValue
        self.aiEnabled = aiEnabled
        self.notificationsEnabled = notificationsEnabled
        self.stepsGoal = stepsGoal
        self.sleepGoalHours = sleepGoalHours
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    public var enabledDomains: [LifeDomain] {
        get {
            guard !enabledDomainsRawValue.isEmpty else { return [] }
            return enabledDomainsRawValue.split(separator: ",")
                .compactMap { LifeDomain(rawValue: String($0)) }
        }
        set {
            enabledDomainsRawValue = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    public var wakeUpHour: Int {
        Calendar.current.component(.hour, from: wakeUpTime)
    }

    public var wakeUpMinute: Int {
        Calendar.current.component(.minute, from: wakeUpTime)
    }
}
