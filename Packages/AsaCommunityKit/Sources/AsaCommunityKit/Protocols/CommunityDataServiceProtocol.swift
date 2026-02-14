import Foundation
import SwiftData

// MARK: - CommunityDataServiceProtocol

/// SwiftData CRUD全体の抽象化プロトコル
@MainActor
public protocol CommunityDataServiceProtocol {
    // MARK: - Community

    func fetchCommunity() throws -> Community?
    func saveCommunity(_ community: Community) throws

    // MARK: - Profile

    func fetchProfile() throws -> CommunityProfile?
    func saveProfile(_ profile: CommunityProfile) throws

    // MARK: - Posts

    func fetchPosts(category: PostCategory?) throws -> [CommunityPost]
    func savePost(_ post: CommunityPost) throws
    func deletePost(_ post: CommunityPost) throws
    func markPostAsRead(_ post: CommunityPost) throws

    // MARK: - Events

    func fetchEvents(includePast: Bool) throws -> [CommunityEvent]
    func fetchUpcomingEvents(limit: Int) throws -> [CommunityEvent]
    func saveEvent(_ event: CommunityEvent) throws
    func deleteEvent(_ event: CommunityEvent) throws

    // MARK: - RSVP

    func saveRSVP(_ rsvp: EventRSVP, for event: CommunityEvent) throws
    func deleteRSVP(_ rsvp: EventRSVP) throws

    // MARK: - Safety

    func fetchSafetyReports(activeOnly: Bool) throws -> [SafetyReport]
    func saveSafetyReport(_ report: SafetyReport) throws
    func resolveSafetyReport(_ report: SafetyReport) throws

    // MARK: - Shelters

    func fetchShelters() throws -> [EvacuationShelter]
    func saveShelter(_ shelter: EvacuationShelter) throws

    // MARK: - Garbage Schedule

    func fetchGarbageSchedules() throws -> [GarbageSchedule]
    func saveGarbageSchedule(_ schedule: GarbageSchedule) throws
    func deleteGarbageSchedule(_ schedule: GarbageSchedule) throws

    // MARK: - Local Business

    func fetchBusinesses(category: BusinessCategory?) throws -> [LocalBusiness]
    func saveBusiness(_ business: LocalBusiness) throws
    func toggleFavorite(_ business: LocalBusiness) throws

    // MARK: - Settings

    func fetchSettings() throws -> CommunitySettings
    func saveSettings(_ settings: CommunitySettings) throws

    // MARK: - Save

    func save() throws
}
