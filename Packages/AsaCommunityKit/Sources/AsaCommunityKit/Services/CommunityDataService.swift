import Foundation
import SwiftData

// MARK: - CommunityDataService

/// SwiftDataベースのコミュニティデータ永続化サービス
@MainActor
public final class CommunityDataService: CommunityDataServiceProtocol {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Community

    public func fetchCommunity() throws -> Community? {
        let descriptor = FetchDescriptor<Community>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    public func saveCommunity(_ community: Community) throws {
        modelContext.insert(community)
        try modelContext.save()
    }

    // MARK: - Profile

    public func fetchProfile() throws -> CommunityProfile? {
        let descriptor = FetchDescriptor<CommunityProfile>(
            sortBy: [SortDescriptor(\.joinedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    public func saveProfile(_ profile: CommunityProfile) throws {
        modelContext.insert(profile)
        try modelContext.save()
    }

    // MARK: - Posts

    public func fetchPosts(category: PostCategory?) throws -> [CommunityPost] {
        let posts: [CommunityPost]
        if let category {
            let rawValue = category.rawValue
            let descriptor = FetchDescriptor<CommunityPost>(
                predicate: #Predicate { $0.categoryRawValue == rawValue },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            posts = try modelContext.fetch(descriptor)
        } else {
            let descriptor = FetchDescriptor<CommunityPost>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            posts = try modelContext.fetch(descriptor)
        }
        // ピン止め投稿を先頭に表示（Bool は SortDescriptor 不可のため手動ソート）
        return posts.sorted { lhs, _ in lhs.isPinned }
    }

    public func savePost(_ post: CommunityPost) throws {
        modelContext.insert(post)
        try modelContext.save()
    }

    public func deletePost(_ post: CommunityPost) throws {
        modelContext.delete(post)
        try modelContext.save()
    }

    public func markPostAsRead(_ post: CommunityPost) throws {
        post.isRead = true
        try modelContext.save()
    }

    // MARK: - Events

    public func fetchEvents(includePast: Bool) throws -> [CommunityEvent] {
        if includePast {
            let descriptor = FetchDescriptor<CommunityEvent>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } else {
            let now = Date()
            let descriptor = FetchDescriptor<CommunityEvent>(
                predicate: #Predicate { $0.endDate >= now },
                sortBy: [SortDescriptor(\.startDate, order: .forward)]
            )
            return try modelContext.fetch(descriptor)
        }
    }

    public func fetchUpcomingEvents(limit: Int) throws -> [CommunityEvent] {
        let now = Date()
        var descriptor = FetchDescriptor<CommunityEvent>(
            predicate: #Predicate { $0.startDate >= now },
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    public func saveEvent(_ event: CommunityEvent) throws {
        modelContext.insert(event)
        try modelContext.save()
    }

    public func deleteEvent(_ event: CommunityEvent) throws {
        modelContext.delete(event)
        try modelContext.save()
    }

    // MARK: - RSVP

    public func saveRSVP(_ rsvp: EventRSVP, for event: CommunityEvent) throws {
        rsvp.event = event
        event.rsvps.append(rsvp)
        modelContext.insert(rsvp)
        try modelContext.save()
    }

    public func deleteRSVP(_ rsvp: EventRSVP) throws {
        if let event = rsvp.event {
            event.rsvps.removeAll { $0.id == rsvp.id }
        }
        modelContext.delete(rsvp)
        try modelContext.save()
    }

    // MARK: - Safety

    public func fetchSafetyReports(activeOnly: Bool) throws -> [SafetyReport] {
        if activeOnly {
            let descriptor = FetchDescriptor<SafetyReport>(
                predicate: #Predicate { !$0.isResolved },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } else {
            let descriptor = FetchDescriptor<SafetyReport>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        }
    }

    public func saveSafetyReport(_ report: SafetyReport) throws {
        modelContext.insert(report)
        try modelContext.save()
    }

    public func resolveSafetyReport(_ report: SafetyReport) throws {
        report.isResolved = true
        report.resolvedAt = Date()
        try modelContext.save()
    }

    // MARK: - Shelters

    public func fetchShelters() throws -> [EvacuationShelter] {
        let descriptor = FetchDescriptor<EvacuationShelter>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func saveShelter(_ shelter: EvacuationShelter) throws {
        modelContext.insert(shelter)
        try modelContext.save()
    }

    // MARK: - Garbage Schedule

    public func fetchGarbageSchedules() throws -> [GarbageSchedule] {
        let descriptor = FetchDescriptor<GarbageSchedule>(
            sortBy: [SortDescriptor(\.weekday, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func saveGarbageSchedule(_ schedule: GarbageSchedule) throws {
        modelContext.insert(schedule)
        try modelContext.save()
    }

    public func deleteGarbageSchedule(_ schedule: GarbageSchedule) throws {
        modelContext.delete(schedule)
        try modelContext.save()
    }

    // MARK: - Local Business

    public func fetchBusinesses(category: BusinessCategory?) throws -> [LocalBusiness] {
        if let category {
            let rawValue = category.rawValue
            let descriptor = FetchDescriptor<LocalBusiness>(
                predicate: #Predicate { $0.categoryRawValue == rawValue },
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            return try modelContext.fetch(descriptor)
        } else {
            let descriptor = FetchDescriptor<LocalBusiness>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            return try modelContext.fetch(descriptor)
        }
    }

    public func saveBusiness(_ business: LocalBusiness) throws {
        modelContext.insert(business)
        try modelContext.save()
    }

    public func toggleFavorite(_ business: LocalBusiness) throws {
        business.isFavorite.toggle()
        try modelContext.save()
    }

    // MARK: - Settings

    public func fetchSettings() throws -> CommunitySettings {
        let descriptor = FetchDescriptor<CommunitySettings>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        // デフォルト設定を生成して保存
        let defaultSettings = CommunitySettings()
        modelContext.insert(defaultSettings)
        try modelContext.save()
        return defaultSettings
    }

    public func saveSettings(_ settings: CommunitySettings) throws {
        modelContext.insert(settings)
        try modelContext.save()
    }

    // MARK: - Save

    public func save() throws {
        try modelContext.save()
    }
}
