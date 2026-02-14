import Foundation

// MARK: - SafetyViewModel

/// 防犯・防災のViewModel
///
/// 安全レポートの一覧表示、新規作成、解決処理、避難所情報を管理する。
/// 緊急レベルのレポート作成時には通知を送信する。
@MainActor @Observable
public final class SafetyViewModel {
    // MARK: - Dependencies

    public let dataService: CommunityDataServiceProtocol
    public let notificationService: NotificationServiceProtocol

    // MARK: - Properties

    public var safetyReports: [SafetyReport] = []
    public var shelters: [EvacuationShelter] = []
    public var showActiveOnly: Bool = true
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

    /// アクティブなアラート数
    public var activeAlertCount: Int {
        safetyReports.filter { $0.isActiveAlert }.count
    }

    // MARK: - Methods

    /// 安全レポートと避難所データを取得する
    public func loadSafetyData() {
        isLoading = true
        errorMessage = nil
        do {
            safetyReports = try dataService.fetchSafetyReports(activeOnly: showActiveOnly)
            shelters = try dataService.fetchShelters()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 安全レポートを作成し、警告以上なら通知を送信する
    public func createReport(
        title: String,
        description: String = "",
        alertLevel: SafetyAlertLevel,
        latitude: Double = 0.0,
        longitude: Double = 0.0
    ) async {
        isLoading = true
        errorMessage = nil
        do {
            let report = SafetyReport(
                title: title,
                reportDescription: description,
                alertLevel: alertLevel,
                latitude: latitude,
                longitude: longitude
            )
            try dataService.saveSafetyReport(report)
            safetyReports.insert(report, at: 0)

            // 警告以上の場合、安全アラート通知を送信
            if alertLevel >= .warning {
                try await notificationService.sendSafetyAlert(
                    title: title,
                    body: description,
                    level: alertLevel
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// レポートを解決済みにする
    public func resolveReport(_ report: SafetyReport) {
        errorMessage = nil
        do {
            try dataService.resolveSafetyReport(report)
            // ローカルリストも更新
            if let index = safetyReports.firstIndex(where: { $0.id == report.id }) {
                safetyReports[index].isResolved = true
                safetyReports[index].resolvedAt = Date()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
