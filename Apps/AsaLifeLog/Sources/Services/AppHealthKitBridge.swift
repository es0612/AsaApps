import Foundation
import AsaLifeLogKit

// MARK: - AppHealthKitBridge

/// AsaHealthKit と AsaLifeLogKit の橋渡しサービス
///
/// HealthManager から取得した健康データを LifeLogEntry に変換する。
@MainActor
@Observable
final class AppHealthKitBridge {

    /// 指定日の健康データをLifeLogEntryに変換して取得する
    func fetchHealthEntries(for date: Date) async throws -> [LifeLogEntry] {
        // HealthKit が利用不可の場合は空配列を返す
        // 実際のアプリではHealthManagerを通じてデータを取得する
        var entries: [LifeLogEntry] = []

        // 歩数エントリー（例）
        let stepsEntry = LifeLogEntry(
            timestamp: date,
            entryType: .health,
            title: "歩数データ",
            source: .healthKit,
            healthMetricTypeRawValue: "steps",
            healthMetricValue: 0
        )
        entries.append(stepsEntry)

        return entries
    }

    /// HealthKitの認可をリクエストする
    func requestAuthorization() async -> Bool {
        // 実際のアプリではHealthManagerを通じて認可をリクエスト
        return false
    }
}
