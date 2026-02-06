import CoreLocation
import Foundation
import Testing
@testable import AsaSmartReminderKit

// MARK: - ReminderLocation テスト

@Suite("ReminderLocation")
struct ReminderLocationTests {

    // MARK: - 初期化

    @Test("デフォルト値での初期化")
    func defaultInit() {
        let location = ReminderLocation(
            name: "イオンモール",
            latitude: 35.6812,
            longitude: 139.7671
        )
        #expect(location.name == "イオンモール")
        #expect(location.latitude == 35.6812)
        #expect(location.longitude == 139.7671)
        #expect(location.radius == 100)
        #expect(location.category == .custom)
        #expect(location.address == nil)
    }

    @Test("カスタム値での初期化")
    func customInit() {
        let location = ReminderLocation(
            name: "自宅",
            latitude: 35.6812,
            longitude: 139.7671,
            radius: 50,
            address: "東京都千代田区",
            category: .home
        )
        #expect(location.name == "自宅")
        #expect(location.radius == 50)
        #expect(location.address == "東京都千代田区")
        #expect(location.category == .home)
    }

    // MARK: - Computed Properties

    @Test("CLLocationCoordinate2Dの取得")
    func coordinate() {
        let location = ReminderLocation(
            name: "テスト",
            latitude: 35.6812,
            longitude: 139.7671
        )
        #expect(location.coordinate.latitude == 35.6812)
        #expect(location.coordinate.longitude == 139.7671)
    }

    @Test("カテゴリのget/set")
    func categoryGetSet() {
        let location = ReminderLocation(
            name: "テスト",
            latitude: 35.0,
            longitude: 139.0,
            category: .home
        )
        #expect(location.category == .home)
        #expect(location.categoryRawValue == "home")

        location.category = .work
        #expect(location.category == .work)
        #expect(location.categoryRawValue == "work")
    }

    @Test("不正なrawValueではcustomに戻る")
    func invalidCategoryRawValue() {
        let location = ReminderLocation(
            name: "テスト",
            latitude: 35.0,
            longitude: 139.0
        )
        location.categoryRawValue = "invalid"
        #expect(location.category == .custom)
    }

    // MARK: - activeReminderCount

    @Test("リマインダーなしでアクティブ数は0")
    func noRemindersActiveCount() {
        let location = ReminderLocation(
            name: "テスト",
            latitude: 35.0,
            longitude: 139.0
        )
        #expect(location.activeReminderCount == 0)
    }

    // MARK: - distance

    @Test("同じ座標への距離は0")
    func distanceToSamePoint() {
        let location = ReminderLocation(
            name: "テスト",
            latitude: 35.6812,
            longitude: 139.7671
        )
        let coord = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        #expect(location.distance(from: coord) < 1.0) // 浮動小数点誤差を考慮
    }

    @Test("異なる座標への距離は正の値")
    func distanceToDifferentPoint() {
        let location = ReminderLocation(
            name: "東京駅",
            latitude: 35.6812,
            longitude: 139.7671
        )
        // 新宿駅の座標
        let shinjuku = CLLocationCoordinate2D(latitude: 35.6896, longitude: 139.7006)
        let distance = location.distance(from: shinjuku)
        #expect(distance > 5000) // 約6.4km
        #expect(distance < 10000)
    }
}
