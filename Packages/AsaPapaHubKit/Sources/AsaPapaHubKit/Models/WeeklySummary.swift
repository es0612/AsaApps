import Foundation
import SwiftData

// MARK: - 週次サマリー

@Model
public final class WeeklySummary {
    public var id: UUID
    public var weekStartDate: Date
    public var weekEndDate: Date
    public var summaryText: String
    public var highlightsJSON: String
    public var suggestionsJSON: String
    public var averageMorningScore: Int
    public var statusRawValue: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        weekStartDate: Date = Date(),
        weekEndDate: Date = Date(),
        summaryText: String = "",
        highlightsJSON: String = "[]",
        suggestionsJSON: String = "[]",
        averageMorningScore: Int = 0,
        statusRawValue: String = BriefingStatus.pending.rawValue,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.summaryText = summaryText
        self.highlightsJSON = highlightsJSON
        self.suggestionsJSON = suggestionsJSON
        self.averageMorningScore = averageMorningScore
        self.statusRawValue = statusRawValue
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    public var status: BriefingStatus {
        get { BriefingStatus(rawValue: statusRawValue) ?? .pending }
        set { statusRawValue = newValue.rawValue }
    }

    public var highlights: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(highlightsJSON.utf8))) ?? []
        }
        set {
            highlightsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    public var suggestions: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(suggestionsJSON.utf8))) ?? []
        }
        set {
            suggestionsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }
}
