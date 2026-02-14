import Foundation

// MARK: - EventCalendarViewModel

/// イベントカレンダーのViewModel
///
/// イベント一覧、日付フィルタ、RSVP、リマインダー設定を管理する。
@MainActor @Observable
public final class EventCalendarViewModel {
    // MARK: - Dependencies

    private let dataService: CommunityDataServiceProtocol
    private let notificationService: NotificationServiceProtocol

    // MARK: - Properties

    public var events: [CommunityEvent] = []
    public var selectedDate: Date = Date()
    public var showPastEvents: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(
        dataService: CommunityDataServiceProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.dataService = dataService
        self.notificationService = notificationService
    }

    // MARK: - Computed Properties

    /// 選択中の日付のイベント
    public var eventsForSelectedDate: [CommunityEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: selectedDate)
        }
    }

    /// 未来のイベント（新しい順）
    public var upcomingEvents: [CommunityEvent] {
        let now = Date()
        return events
            .filter { $0.startDate >= now }
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Methods

    /// イベントを取得する
    public func loadEvents() {
        isLoading = true
        errorMessage = nil
        do {
            events = try dataService.fetchEvents(includePast: showPastEvents)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// イベントを作成する
    public func createEvent(
        title: String,
        description: String = "",
        location: String,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        startDate: Date,
        endDate: Date,
        maxParticipants: Int = 0
    ) {
        isLoading = true
        errorMessage = nil
        do {
            let event = CommunityEvent(
                title: title,
                eventDescription: description,
                location: location,
                latitude: latitude,
                longitude: longitude,
                startDate: startDate,
                endDate: endDate,
                maxParticipants: maxParticipants
            )
            try dataService.saveEvent(event)
            events.append(event)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// イベントを削除する
    public func deleteEvent(_ event: CommunityEvent) {
        errorMessage = nil
        do {
            try dataService.deleteEvent(event)
            events.removeAll { $0.id == event.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// RSVP を保存し、参加の場合はリマインダーを設定する
    public func rsvpToEvent(_ event: CommunityEvent, status: RSVPStatus) async {
        errorMessage = nil
        do {
            let rsvp = EventRSVP(status: status)
            try dataService.saveRSVP(rsvp, for: event)

            // 参加の場合、30分前リマインダーを設定
            if status == .attending {
                try await notificationService.scheduleEventReminder(
                    eventTitle: event.title,
                    eventDate: event.startDate,
                    minutesBefore: 30
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
