import Foundation

// MARK: - 家族ViewModel

@MainActor
@Observable
public final class FamilyViewModel {
    // MARK: - Supporting Types

    public struct FamilyEvent: Identifiable, Sendable {
        public var id: UUID
        public var title: String
        public var date: Date
        public var iconName: String

        public init(id: UUID = UUID(), title: String, date: Date, iconName: String = "calendar") {
            self.id = id
            self.title = title
            self.date = date
            self.iconName = iconName
        }
    }

    public struct KidsLearningItem: Identifiable, Sendable {
        public var id: UUID
        public var childName: String
        public var subject: String
        public var progress: Double

        public init(id: UUID = UUID(), childName: String, subject: String, progress: Double) {
            self.id = id
            self.childName = childName
            self.subject = subject
            self.progress = progress
        }
    }

    // MARK: - Properties

    public var familyEvents: [FamilyEvent] = []
    public var kidsLearning: [KidsLearningItem] = []
    public var isLoading = false
    public var error: PapaHubError?

    private let dataService: HubDataServiceProtocol

    // MARK: - Init

    public init(dataService: HubDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    public func loadFamilyData() async {
        isLoading = true
        error = nil
        do {
            let snapshots = try await dataService.fetchSnapshots(for: Date())
            let familySnapshot = snapshots.first { $0.domain == .family }

            if let detail = familySnapshot?.detailJSON,
               let data = detail.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                if let events = json["events"] as? [[String: String]] {
                    familyEvents = events.compactMap { dict in
                        guard let title = dict["title"] else { return nil }
                        return FamilyEvent(title: title, date: Date(), iconName: dict["icon"] ?? "calendar")
                    }
                }
            }

            if familyEvents.isEmpty {
                familyEvents = [
                    FamilyEvent(title: "家族の朝食", date: Date(), iconName: "fork.knife"),
                    FamilyEvent(title: "公園で遊ぶ", date: Date(), iconName: "figure.play"),
                ]
            }
            if kidsLearning.isEmpty {
                kidsLearning = [
                    KidsLearningItem(childName: "ゆうと", subject: "算数", progress: 0.7),
                    KidsLearningItem(childName: "はな", subject: "ひらがな", progress: 0.5),
                ]
            }
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
        }
        isLoading = false
    }
}
