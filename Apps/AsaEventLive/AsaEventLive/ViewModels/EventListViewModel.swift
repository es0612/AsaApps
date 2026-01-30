import Foundation
import SwiftUI

// MARK: - EventListViewModel

@Observable
@MainActor
final class EventListViewModel {
    // MARK: - Properties

    private(set) var events: [Event] = []
    private(set) var isLoading: Bool = false
    var errorMessage: String?

    private let dataService: any EventDataServiceProtocol
    private let userId: String
    private var eventsListener: Any?

    // MARK: - Computed Properties

    var liveEvents: [Event] {
        events.filter { $0.status == .live }
    }

    var upcomingEvents: [Event] {
        events.filter { $0.status == .upcoming }
    }

    var pastEvents: [Event] {
        events.filter { $0.status == .ended }
    }

    var hasEvents: Bool {
        !events.isEmpty
    }

    // MARK: - Initialization

    init(dataService: any EventDataServiceProtocol, userId: String) {
        self.dataService = dataService
        self.userId = userId
    }

    // Note: ViewのonDisappearでstopObserving()を呼び出してリスナーを解除する
    // deinitからはMainActor隔離プロパティにアクセスできないため、明示的な解除が必要

    // MARK: - Public Methods

    func startObserving() {
        eventsListener = dataService.observeEvents(userId: userId) { [weak self] events in
            Task { @MainActor [weak self] in
                self?.events = events
            }
        }
    }

    func stopObserving() {
        if let listener = eventsListener {
            dataService.removeListener(listener)
            eventsListener = nil
        }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            events = try await dataService.fetchEvents(userId: userId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func createEvent(
        title: String,
        description: String,
        category: EventCategory,
        location: String?,
        startDate: Date,
        endDate: Date?
    ) async throws -> Event {
        let event = Event(
            title: title,
            description: description,
            category: category,
            location: location,
            startDate: startDate,
            endDate: endDate,
            hostId: userId,
            hostName: "ホスト", // 実際のアプリでは認証ユーザーの名前を使用
            participantIds: [userId]
        )

        return try await dataService.createEvent(event)
    }

    func deleteEvent(_ eventId: String) async throws {
        try await dataService.deleteEvent(eventId)
    }

    func joinEvent(inviteCode: String, displayName: String) async throws -> Event {
        // 招待コードからイベントを検索
        let normalizedCode = InviteCodeGenerator.normalize(inviteCode)

        // 全イベントを取得して招待コードで検索（実際の実装ではサーバーサイドで検索）
        let allEvents = events + (try await dataService.fetchEvents(userId: ""))
        guard let event = allEvents.first(where: { $0.inviteCode == normalizedCode }) else {
            throw EventDataError.invalidInviteCode
        }

        let participant = Participant(
            eventId: event.id,
            userId: userId,
            displayName: displayName,
            role: .participant,
            onlineStatus: .online
        )

        return try await dataService.joinEvent(
            eventId: event.id,
            inviteCode: normalizedCode,
            participant: participant
        )
    }

    func clearError() {
        errorMessage = nil
    }
}
