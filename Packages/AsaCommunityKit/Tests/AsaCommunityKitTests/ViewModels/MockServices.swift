import Foundation
import CoreLocation

@testable import AsaCommunityKit

// MARK: - MockCommunityDataService

/// テスト用のモックデータサービス
@MainActor
final class MockCommunityDataService: CommunityDataServiceProtocol {
    var shouldThrow: Bool = false

    // インメモリストレージ
    var community: Community?
    var profile: CommunityProfile?
    var posts: [CommunityPost] = []
    var events: [CommunityEvent] = []
    var safetyReports: [SafetyReport] = []
    var shelters: [EvacuationShelter] = []
    var garbageSchedules: [GarbageSchedule] = []
    var businesses: [LocalBusiness] = []
    var settings: CommunitySettings = CommunitySettings()

    private func throwIfNeeded() throws {
        if shouldThrow { throw CommunityError.dataServiceError("mock error") }
    }

    // MARK: - Community

    func fetchCommunity() throws -> Community? {
        try throwIfNeeded()
        return community
    }

    func saveCommunity(_ community: Community) throws {
        try throwIfNeeded()
        self.community = community
    }

    // MARK: - Profile

    func fetchProfile() throws -> CommunityProfile? {
        try throwIfNeeded()
        return profile
    }

    func saveProfile(_ profile: CommunityProfile) throws {
        try throwIfNeeded()
        self.profile = profile
    }

    // MARK: - Posts

    func fetchPosts(category: PostCategory?) throws -> [CommunityPost] {
        try throwIfNeeded()
        if let category {
            return posts.filter { $0.category == category }
        }
        return posts
    }

    func savePost(_ post: CommunityPost) throws {
        try throwIfNeeded()
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
        } else {
            posts.append(post)
        }
    }

    func deletePost(_ post: CommunityPost) throws {
        try throwIfNeeded()
        posts.removeAll { $0.id == post.id }
    }

    func markPostAsRead(_ post: CommunityPost) throws {
        try throwIfNeeded()
        post.isRead = true
    }

    // MARK: - Events

    func fetchEvents(includePast: Bool) throws -> [CommunityEvent] {
        try throwIfNeeded()
        if includePast {
            return events
        }
        return events.filter { !$0.isPast }
    }

    func fetchUpcomingEvents(limit: Int) throws -> [CommunityEvent] {
        try throwIfNeeded()
        return Array(events.filter { !$0.isPast }.prefix(limit))
    }

    func saveEvent(_ event: CommunityEvent) throws {
        try throwIfNeeded()
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
    }

    func deleteEvent(_ event: CommunityEvent) throws {
        try throwIfNeeded()
        events.removeAll { $0.id == event.id }
    }

    // MARK: - RSVP

    func saveRSVP(_ rsvp: EventRSVP, for event: CommunityEvent) throws {
        try throwIfNeeded()
        event.rsvps.append(rsvp)
    }

    func deleteRSVP(_ rsvp: EventRSVP) throws {
        try throwIfNeeded()
    }

    // MARK: - Safety

    func fetchSafetyReports(activeOnly: Bool) throws -> [SafetyReport] {
        try throwIfNeeded()
        if activeOnly {
            return safetyReports.filter { !$0.isResolved }
        }
        return safetyReports
    }

    func saveSafetyReport(_ report: SafetyReport) throws {
        try throwIfNeeded()
        safetyReports.append(report)
    }

    func resolveSafetyReport(_ report: SafetyReport) throws {
        try throwIfNeeded()
        report.isResolved = true
        report.resolvedAt = Date()
    }

    // MARK: - Shelters

    func fetchShelters() throws -> [EvacuationShelter] {
        try throwIfNeeded()
        return shelters
    }

    func saveShelter(_ shelter: EvacuationShelter) throws {
        try throwIfNeeded()
        shelters.append(shelter)
    }

    // MARK: - Garbage Schedule

    func fetchGarbageSchedules() throws -> [GarbageSchedule] {
        try throwIfNeeded()
        return garbageSchedules
    }

    func saveGarbageSchedule(_ schedule: GarbageSchedule) throws {
        try throwIfNeeded()
        garbageSchedules.append(schedule)
    }

    func deleteGarbageSchedule(_ schedule: GarbageSchedule) throws {
        try throwIfNeeded()
        garbageSchedules.removeAll { $0.id == schedule.id }
    }

    // MARK: - Local Business

    func fetchBusinesses(category: BusinessCategory?) throws -> [LocalBusiness] {
        try throwIfNeeded()
        if let category {
            return businesses.filter { $0.category == category }
        }
        return businesses
    }

    func saveBusiness(_ business: LocalBusiness) throws {
        try throwIfNeeded()
        businesses.append(business)
    }

    func toggleFavorite(_ business: LocalBusiness) throws {
        try throwIfNeeded()
        // データサービスは永続化のみ。実際のトグルはViewModelが行う
    }

    // MARK: - Settings

    func fetchSettings() throws -> CommunitySettings {
        try throwIfNeeded()
        return settings
    }

    func saveSettings(_ settings: CommunitySettings) throws {
        try throwIfNeeded()
        self.settings = settings
    }

    // MARK: - Save

    func save() throws {
        try throwIfNeeded()
    }
}

// MARK: - MockFeedService

/// テスト用のモックフィードサービス
@MainActor
final class MockFeedService: CommunityFeedServiceProtocol {
    var shouldThrow: Bool = false
    var postsToReturn: [CommunityPost] = []
    var eventsToReturn: [CommunityEvent] = []
    var alertsToReturn: [SafetyReport] = []
    var submittedPosts: [CommunityPost] = []
    var submittedEvents: [CommunityEvent] = []
    var submittedReports: [SafetyReport] = []

    private func throwIfNeeded() throws {
        if shouldThrow { throw CommunityError.networkError("mock network error") }
    }

    func fetchLatestPosts(since: Date?) async throws -> [CommunityPost] {
        try throwIfNeeded()
        return postsToReturn
    }

    func fetchLatestEvents(since: Date?) async throws -> [CommunityEvent] {
        try throwIfNeeded()
        return eventsToReturn
    }

    func fetchSafetyAlerts() async throws -> [SafetyReport] {
        try throwIfNeeded()
        return alertsToReturn
    }

    func submitPost(_ post: CommunityPost) async throws {
        try throwIfNeeded()
        submittedPosts.append(post)
    }

    func submitEvent(_ event: CommunityEvent) async throws {
        try throwIfNeeded()
        submittedEvents.append(event)
    }

    func submitSafetyReport(_ report: SafetyReport) async throws {
        try throwIfNeeded()
        submittedReports.append(report)
    }
}

// MARK: - MockLocationService

/// テスト用のモック位置情報サービス
@MainActor
final class MockLocationService: LocationServiceProtocol {
    var currentLocation: CLLocation? = CLLocation(latitude: 35.6812, longitude: 139.7671)
    #if os(iOS)
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    #else
    var authorizationStatus: CLAuthorizationStatus = .authorizedAlways
    #endif
    var requestAuthorizationCalled: Bool = false
    var startUpdatingCalled: Bool = false
    var stopUpdatingCalled: Bool = false

    func requestAuthorization() {
        requestAuthorizationCalled = true
    }

    func startUpdatingLocation() {
        startUpdatingCalled = true
    }

    func stopUpdatingLocation() {
        stopUpdatingCalled = true
    }

    func distance(from: CLLocation, to: CLLocation) -> CLLocationDistance {
        from.distance(from: to)
    }

    func distanceFromCurrent(latitude: Double, longitude: Double) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        return current.distance(from: CLLocation(latitude: latitude, longitude: longitude))
    }
}

// MARK: - MockNotificationService

/// テスト用のモック通知サービス
@MainActor
final class MockNotificationService: NotificationServiceProtocol {
    var shouldThrow: Bool = false
    var authorizationGranted: Bool = true
    var requestAuthorizationCallCount: Int = 0
    var scheduledGarbageReminders: [(garbageType: GarbageType, weekday: Int, hour: Int, minute: Int)] = []
    var scheduledEventReminders: [(eventTitle: String, eventDate: Date, minutesBefore: Int)] = []
    var sentSafetyAlerts: [(title: String, body: String, level: SafetyAlertLevel)] = []
    var removeAllCalled: Bool = false
    var removedIdentifiers: [String] = []

    private func throwIfNeeded() throws {
        if shouldThrow { throw CommunityError.notificationPermissionDenied }
    }

    func requestAuthorization() async throws -> Bool {
        try throwIfNeeded()
        requestAuthorizationCallCount += 1
        return authorizationGranted
    }

    func checkAuthorizationStatus() async -> Bool {
        return authorizationGranted
    }

    func scheduleGarbageReminder(
        garbageType: GarbageType,
        weekday: Int,
        hour: Int,
        minute: Int
    ) async throws {
        try throwIfNeeded()
        scheduledGarbageReminders.append((garbageType, weekday, hour, minute))
    }

    func scheduleEventReminder(
        eventTitle: String,
        eventDate: Date,
        minutesBefore: Int
    ) async throws {
        try throwIfNeeded()
        scheduledEventReminders.append((eventTitle, eventDate, minutesBefore))
    }

    func sendSafetyAlert(
        title: String,
        body: String,
        level: SafetyAlertLevel
    ) async throws {
        try throwIfNeeded()
        sentSafetyAlerts.append((title, body, level))
    }

    func removeAllPendingNotifications() async {
        removeAllCalled = true
    }

    func removePendingNotification(identifier: String) async {
        removedIdentifiers.append(identifier)
    }
}

// MARK: - MockContentModerator

/// テスト用のモックコンテンツモデレーター
struct MockContentModerator: ContentModerating {
    var resultToReturn: ModerationResult
    var languageToReturn: String?

    init(
        resultToReturn: ModerationResult = ModerationResult(
            sentimentScore: 0.5,
            detectedLanguage: "ja",
            isAcceptable: true,
            warningMessage: nil
        ),
        languageToReturn: String? = "ja"
    ) {
        self.resultToReturn = resultToReturn
        self.languageToReturn = languageToReturn
    }

    func analyzeSentiment(text: String) -> ModerationResult {
        resultToReturn
    }

    func detectLanguage(text: String) -> String? {
        languageToReturn
    }
}
