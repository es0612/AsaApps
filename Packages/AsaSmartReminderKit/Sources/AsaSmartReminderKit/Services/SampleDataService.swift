#if os(iOS)
import CoreLocation
import Foundation
import SwiftData

// MARK: - サンプルデータサービス

/// デモ動画撮影用のサンプルデータを生成
/// 東京近郊の家族向けスポット5箇所と、各場所に紐付くリマインダー10件を投入
@MainActor
public final class SampleDataService {
    // MARK: - Properties

    private let dataService: ReminderDataService

    // MARK: - Init

    public init(dataService: ReminderDataService) {
        self.dataService = dataService
    }

    // MARK: - Public Methods

    /// サンプルデータを一括投入
    public func loadSampleData() throws {
        // 1. 場所を作成
        let locations = createSampleLocations()
        for location in locations {
            try dataService.saveLocation(location)
        }

        // 2. リマインダーを各場所に紐付けて作成
        try createSampleReminders(locations: locations)
    }

    // MARK: - Sample Locations

    /// 東京近郊の家族向けスポット5箇所
    private func createSampleLocations() -> [ReminderLocation] {
        return [
            // 自宅: 渋谷区神宮前
            ReminderLocation(
                name: "自宅",
                latitude: 35.6707,
                longitude: 139.7095,
                radius: 50,
                address: "東京都渋谷区神宮前",
                category: .home
            ),
            // 職場: 新宿駅周辺
            ReminderLocation(
                name: "オフィス",
                latitude: 35.6896,
                longitude: 139.7006,
                radius: 100,
                address: "東京都新宿区西新宿1丁目",
                category: .work
            ),
            // 子供の小学校: 渋谷区代々木
            ReminderLocation(
                name: "代々木小学校",
                latitude: 35.6750,
                longitude: 139.7016,
                radius: 80,
                address: "東京都渋谷区代々木5丁目",
                category: .school
            ),
            // 行きつけのスーパー: 表参道
            ReminderLocation(
                name: "表参道スーパー",
                latitude: 35.6654,
                longitude: 139.7124,
                radius: 60,
                address: "東京都港区北青山3丁目",
                category: .supermarket
            ),
            // 公園: 代々木公園
            ReminderLocation(
                name: "代々木公園",
                latitude: 35.6720,
                longitude: 139.6951,
                radius: 200,
                address: "東京都渋谷区代々木神園町",
                category: .park
            ),
        ]
    }

    // MARK: - Sample Reminders

    /// リマインダー10件を各場所に紐付けて作成
    private func createSampleReminders(locations: [ReminderLocation]) throws {
        let home = locations[0]
        let office = locations[1]
        let school = locations[2]
        let supermarket = locations[3]
        let park = locations[4]

        let now = Date()
        let calendar = Calendar.current

        let reminderConfigs: [(LocationReminder)] = [
            // 自宅
            LocationReminder(
                title: "ゴミ出しを忘れずに",
                note: "明日は燃えるゴミの日。朝8時までに出す",
                triggerOnExit: true,
                isRepeating: true,
                location: home,
                createdAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now
            ),
            LocationReminder(
                title: "鍵を持ったか確認",
                note: "玄関の鍵と車の鍵をチェック",
                triggerOnExit: true,
                isRepeating: true,
                location: home,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),

            // オフィス
            LocationReminder(
                title: "プロジェクト資料を提出",
                note: "10時の会議までに上司にメール",
                triggerOnEntry: true,
                triggerOnExit: false,
                isRepeating: false,
                location: office,
                createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now
            ),
            LocationReminder(
                title: "退勤前にPCを閉じる",
                note: "セキュリティのため必ずロック",
                triggerOnEntry: false,
                triggerOnExit: true,
                isRepeating: true,
                location: office,
                createdAt: calendar.date(byAdding: .day, value: -5, to: now) ?? now
            ),

            // 小学校
            LocationReminder(
                title: "息子のお迎え",
                note: "15時に正門前で待ち合わせ",
                triggerOnEntry: true,
                triggerOnExit: false,
                isRepeating: true,
                location: school,
                createdAt: calendar.date(byAdding: .day, value: -7, to: now) ?? now
            ),
            LocationReminder(
                title: "PTA連絡帳を提出",
                note: "担任の先生に渡す",
                triggerOnEntry: true,
                triggerOnExit: false,
                isCompleted: true,
                completedAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                isActive: false,
                location: school,
                createdAt: calendar.date(byAdding: .day, value: -10, to: now) ?? now
            ),

            // スーパー
            LocationReminder(
                title: "牛乳と卵を買う",
                note: "明日の朝食に必要",
                triggerOnEntry: true,
                triggerOnExit: false,
                isRepeating: false,
                location: supermarket,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            LocationReminder(
                title: "夕飯の食材を買う",
                note: "鶏肉、玉ねぎ、ピーマン",
                triggerOnEntry: true,
                triggerOnExit: false,
                isRepeating: false,
                location: supermarket,
                createdAt: calendar.date(byAdding: .hour, value: -3, to: now) ?? now
            ),

            // 公園
            LocationReminder(
                title: "子供の水筒を持参",
                note: "暑いので水分補給を忘れずに",
                triggerOnEntry: true,
                triggerOnExit: false,
                isRepeating: true,
                location: park,
                createdAt: calendar.date(byAdding: .day, value: -4, to: now) ?? now
            ),
            LocationReminder(
                title: "帰り際にゴミを拾う",
                note: "公園を綺麗に",
                triggerOnEntry: false,
                triggerOnExit: true,
                isRepeating: true,
                location: park,
                createdAt: calendar.date(byAdding: .day, value: -6, to: now) ?? now
            ),
        ]

        for reminder in reminderConfigs {
            try dataService.saveReminder(reminder)
        }
    }
}
#endif
