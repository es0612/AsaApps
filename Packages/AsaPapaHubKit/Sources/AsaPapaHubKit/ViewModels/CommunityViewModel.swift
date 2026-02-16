import Foundation

// MARK: - 地域コミュニティViewModel

@MainActor
@Observable
public final class CommunityViewModel {
    // MARK: - Supporting Types

    public struct LocalEvent: Identifiable, Sendable {
        public var id: UUID
        public var title: String
        public var date: Date
        public var location: String

        public init(id: UUID = UUID(), title: String, date: Date, location: String) {
            self.id = id
            self.title = title
            self.date = date
            self.location = location
        }
    }

    public struct SafetyStatus: Sendable {
        public var level: String
        public var message: String
        public var iconName: String

        public init(level: String = "安全", message: String = "特に問題はありません", iconName: String = "checkmark.shield.fill") {
            self.level = level
            self.message = message
            self.iconName = iconName
        }
    }

    // MARK: - Properties

    public var localEvents: [LocalEvent] = []
    public var safetyStatus: SafetyStatus = SafetyStatus()
    public var isLoading = false
    public var error: PapaHubError?

    private let dataService: HubDataServiceProtocol

    // MARK: - Init

    public init(dataService: HubDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    public func loadCommunityData() async {
        isLoading = true
        error = nil
        do {
            let snapshots = try await dataService.fetchSnapshots(for: Date())
            _ = snapshots.first { $0.domain == .community }

            if localEvents.isEmpty {
                localEvents = [
                    LocalEvent(title: "朝活ランニング会", date: Date(), location: "中央公園"),
                    LocalEvent(title: "町内清掃活動", date: Date(), location: "駅前広場"),
                ]
            }
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
        }
        isLoading = false
    }
}
