import Foundation
import SwiftData

/// データ永続化サービス
/// Swift Dataを使用してStudyItem、StudySession、StudyPlan等を管理
@MainActor
final class DataService {
    // MARK: - Properties

    let modelContainer: ModelContainer
    let modelContext: ModelContext

    // MARK: - Initializer

    init(inMemory: Bool = false) {
        let schema = Schema([
            StudyItem.self,
            StudySession.self,
            StudyPlan.self,
            LearningAnalytics.self,
            UserLearningProfile.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // MARK: - Save

    func save() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    // MARK: - StudyItem CRUD

    func createStudyItem(
        title: String,
        description: String? = nil,
        category: StudyCategory = .other,
        difficulty: DifficultyLevel = .medium,
        estimatedMinutes: Int = 30,
        targetDate: Date? = nil,
        prerequisiteItemIds: [UUID] = []
    ) -> StudyItem {
        let item = StudyItem(
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            estimatedMinutes: estimatedMinutes,
            targetDate: targetDate,
            prerequisiteItemIds: prerequisiteItemIds
        )
        modelContext.insert(item)
        save()
        return item
    }

    func fetchStudyItems(
        includeArchived: Bool = false,
        includeCompleted: Bool = true
    ) -> [StudyItem] {
        var descriptor = FetchDescriptor<StudyItem>(
            sortBy: [SortDescriptor(\.aiPriorityScore, order: .reverse)]
        )

        do {
            var items = try modelContext.fetch(descriptor)

            if !includeArchived {
                items = items.filter { !$0.isArchived }
            }
            if !includeCompleted {
                items = items.filter { !$0.isCompleted }
            }

            return items
        } catch {
            print("Error fetching study items: \(error)")
            return []
        }
    }

    func fetchStudyItem(byId id: UUID) -> StudyItem? {
        let descriptor = FetchDescriptor<StudyItem>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching study item: \(error)")
            return nil
        }
    }

    func fetchItemsNeedingReview() -> [StudyItem] {
        let now = Date()
        let descriptor = FetchDescriptor<StudyItem>(
            predicate: #Predicate { item in
                item.nextReviewDate != nil && !item.isCompleted && !item.isArchived
            },
            sortBy: [SortDescriptor(\.nextReviewDate)]
        )

        do {
            let items = try modelContext.fetch(descriptor)
            return items.filter { item in
                guard let reviewDate = item.nextReviewDate else { return false }
                return reviewDate <= now
            }
        } catch {
            print("Error fetching items needing review: \(error)")
            return []
        }
    }

    func deleteStudyItem(_ item: StudyItem) {
        modelContext.delete(item)
        save()
    }

    // MARK: - StudySession CRUD

    func createStudySession(
        studyItemId: UUID,
        plannedMinutes: Int = 25
    ) -> StudySession {
        let session = StudySession(
            studyItemId: studyItemId,
            plannedMinutes: plannedMinutes
        )
        modelContext.insert(session)
        save()
        return session
    }

    func fetchStudySessions(
        for itemId: UUID? = nil,
        limit: Int? = nil
    ) -> [StudySession] {
        var descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )

        if let limit = limit {
            descriptor.fetchLimit = limit
        }

        do {
            var sessions = try modelContext.fetch(descriptor)

            if let itemId = itemId {
                sessions = sessions.filter { $0.studyItemId == itemId }
            }

            return sessions
        } catch {
            print("Error fetching study sessions: \(error)")
            return []
        }
    }

    func fetchSessionsForDate(_ date: Date) -> [StudySession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate { session in
                session.startedAt >= startOfDay && session.startedAt < endOfDay
            },
            sortBy: [SortDescriptor(\.startedAt)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching sessions for date: \(error)")
            return []
        }
    }

    // MARK: - StudyPlan CRUD

    func createStudyPlan(
        for date: Date,
        plannedItemIds: [UUID] = [],
        totalPlannedMinutes: Int = 0,
        morningGoalMinutes: Int = 60
    ) -> StudyPlan {
        let plan = StudyPlan(
            date: date,
            plannedItemIds: plannedItemIds,
            totalPlannedMinutes: totalPlannedMinutes,
            morningGoalMinutes: morningGoalMinutes
        )
        modelContext.insert(plan)
        save()
        return plan
    }

    func fetchStudyPlan(for date: Date) -> StudyPlan? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let descriptor = FetchDescriptor<StudyPlan>(
            predicate: #Predicate { plan in
                plan.date == startOfDay
            }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching study plan: \(error)")
            return nil
        }
    }

    func fetchOrCreateTodaysPlan(morningGoalMinutes: Int = 60) -> StudyPlan {
        if let existingPlan = fetchStudyPlan(for: Date()) {
            return existingPlan
        }
        return createStudyPlan(for: Date(), morningGoalMinutes: morningGoalMinutes)
    }

    // MARK: - LearningAnalytics CRUD

    func fetchOrCreateAnalytics(for date: Date) -> LearningAnalytics {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let descriptor = FetchDescriptor<LearningAnalytics>(
            predicate: #Predicate { analytics in
                analytics.date == startOfDay
            }
        )

        do {
            if let existing = try modelContext.fetch(descriptor).first {
                return existing
            }
        } catch {
            print("Error fetching analytics: \(error)")
        }

        let analytics = LearningAnalytics(date: date)
        modelContext.insert(analytics)
        save()
        return analytics
    }

    func fetchAnalytics(from startDate: Date, to endDate: Date) -> [LearningAnalytics] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        let descriptor = FetchDescriptor<LearningAnalytics>(
            predicate: #Predicate { analytics in
                analytics.date >= start && analytics.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching analytics range: \(error)")
            return []
        }
    }

    // MARK: - UserLearningProfile CRUD

    func fetchOrCreateProfile() -> UserLearningProfile {
        let descriptor = FetchDescriptor<UserLearningProfile>()

        do {
            if let existing = try modelContext.fetch(descriptor).first {
                return existing
            }
        } catch {
            print("Error fetching profile: \(error)")
        }

        let profile = UserLearningProfile()
        modelContext.insert(profile)
        save()
        return profile
    }

    // MARK: - Bulk Operations

    func deleteAllData() {
        do {
            try modelContext.delete(model: StudyItem.self)
            try modelContext.delete(model: StudySession.self)
            try modelContext.delete(model: StudyPlan.self)
            try modelContext.delete(model: LearningAnalytics.self)
            save()
        } catch {
            print("Error deleting all data: \(error)")
        }
    }
}
