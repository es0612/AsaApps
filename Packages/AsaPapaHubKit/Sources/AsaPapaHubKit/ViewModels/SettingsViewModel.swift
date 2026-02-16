import Foundation

// MARK: - 設定ViewModel

@MainActor
@Observable
public final class SettingsViewModel {
    // MARK: - Properties

    public var preferences: HubUserPreferences?
    public var isLoading = false
    public var error: PapaHubError?

    private let dataService: HubDataServiceProtocol

    // MARK: - Init

    public init(dataService: HubDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    public func loadPreferences() async {
        isLoading = true
        error = nil
        do {
            preferences = try await dataService.fetchPreferences()
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
        }
        isLoading = false
    }

    public func savePreferences() async {
        guard let preferences else { return }
        do {
            try await dataService.savePreferences(preferences)
        } catch {
            self.error = .saveFailed(error.localizedDescription)
        }
    }

    public func toggleDomain(_ domain: LifeDomain) {
        guard let preferences else { return }
        var domains = preferences.enabledDomains
        if let index = domains.firstIndex(of: domain) {
            domains.remove(at: index)
        } else {
            domains.append(domain)
        }
        preferences.enabledDomains = domains
    }

    public func resetToDefaults() async {
        guard let preferences else { return }
        preferences.wakeUpTime = Calendar.current.date(from: DateComponents(hour: 5, minute: 30)) ?? Date()
        preferences.enabledDomains = LifeDomain.allCases
        preferences.aiEnabled = true
        preferences.notificationsEnabled = true
        preferences.stepsGoal = 10000
        preferences.sleepGoalHours = 7.0
        await savePreferences()
    }
}
