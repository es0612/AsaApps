import Foundation

// MARK: - CommunityHomeViewModel

/// ホーム画面（ダッシュボード）のViewModel
///
/// コミュニティ概要、今日のゴミ出し、直近イベント、未読投稿数、
/// アクティブアラートをまとめて表示する。
@MainActor @Observable
public final class CommunityHomeViewModel {
    // MARK: - Dependencies

    public let dataService: CommunityDataServiceProtocol

    // MARK: - Properties

    public var community: Community?
    public var todaysGarbage: [GarbageSchedule] = []
    public var upcomingEvents: [CommunityEvent] = []
    public var unreadPostCount: Int = 0
    public var activeAlerts: [SafetyReport] = []
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(dataService: CommunityDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    /// ダッシュボード用の全データを一括取得する
    public func loadDashboard() {
        isLoading = true
        errorMessage = nil
        do {
            community = try dataService.fetchCommunity()

            // 今日のゴミ出しスケジュール
            let allSchedules = try dataService.fetchGarbageSchedules()
            todaysGarbage = filterTodaysGarbage(from: allSchedules)

            // 直近イベント（上位5件）
            upcomingEvents = try dataService.fetchUpcomingEvents(limit: 5)

            // 未読投稿数
            let posts = try dataService.fetchPosts(category: nil)
            unreadPostCount = posts.filter { !$0.isRead }.count

            // アクティブアラート
            let reports = try dataService.fetchSafetyReports(activeOnly: true)
            activeAlerts = reports.filter { $0.isActiveAlert }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Private

    /// 今日の曜日に該当するゴミ出しスケジュールを抽出する
    private func filterTodaysGarbage(from schedules: [GarbageSchedule]) -> [GarbageSchedule] {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let todayWeekOfMonth = calendar.component(.weekOfMonth, from: today)

        return schedules.filter { schedule in
            guard schedule.weekday == todayWeekday else { return false }
            // weekOfMonth == 0 は毎週
            return schedule.weekOfMonth == 0 || schedule.weekOfMonth == todayWeekOfMonth
        }
    }
}
