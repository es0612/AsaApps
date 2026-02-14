import Foundation
import SwiftData

// MARK: - CommunityEvent

/// コミュニティイベントモデル
@Model
public final class CommunityEvent {
    public var id: UUID = UUID()
    public var title: String = ""
    public var eventDescription: String = ""
    public var location: String = ""
    public var latitude: Double = 0.0
    public var longitude: Double = 0.0
    public var startDate: Date = Date()
    public var endDate: Date = Date()
    public var maxParticipants: Int = 0
    public var imageData: Data?
    public var isRecurring: Bool = false
    public var createdAt: Date = Date()

    public var community: Community?

    @Relationship(deleteRule: .cascade, inverse: \EventRSVP.event)
    public var rsvps: [EventRSVP] = []

    public init(
        title: String,
        eventDescription: String = "",
        location: String,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        startDate: Date,
        endDate: Date,
        maxParticipants: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.eventDescription = eventDescription
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.startDate = startDate
        self.endDate = endDate
        self.maxParticipants = maxParticipants
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    /// 参加者数
    public var attendeeCount: Int {
        rsvps.filter { $0.status == .attending }.count
    }

    /// 残り枠数（0 = 上限なし）
    public var remainingSlots: Int? {
        guard maxParticipants > 0 else { return nil }
        return max(maxParticipants - attendeeCount, 0)
    }

    /// 開催済みかどうか
    public var isPast: Bool {
        endDate < Date()
    }

    /// 本日開催かどうか
    public var isToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }

    /// 今週開催かどうか
    public var isThisWeek: Bool {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: Date()) else {
            return false
        }
        return startDate >= Date() && startDate <= weekEnd
    }
}
