import CoreLocation
import Foundation
import Testing
@testable import AsaSmartReminderKit

// MARK: - RegionPrioritizer テスト

@Suite("RegionPrioritizer")
struct RegionPrioritizerTests {

    let prioritizer = RegionPrioritizer()

    // MARK: - ヘルパー

    private func makeLocationInfo(
        name: String,
        lat: Double,
        lon: Double,
        activeCount: Int = 1
    ) -> RegionPrioritizer.LocationInfo {
        RegionPrioritizer.LocationInfo(
            id: UUID(),
            name: name,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            radius: 100,
            activeReminderCount: activeCount
        )
    }

    // 東京駅付近の座標
    private var tokyoStation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    }

    // MARK: - prioritize

    @Test("空リストでは空を返す")
    func emptyLocations() {
        let result = prioritizer.prioritize(
            locations: [],
            userCoordinate: tokyoStation
        )
        #expect(result.isEmpty)
    }

    @Test("近い順にソートされる")
    func sortedByDistance() {
        let locations = [
            makeLocationInfo(name: "遠い", lat: 35.6896, lon: 139.7006), // 新宿
            makeLocationInfo(name: "近い", lat: 35.6812, lon: 139.7672), // 東京駅すぐ横
            makeLocationInfo(name: "中間", lat: 35.6585, lon: 139.7454), // 品川
        ]
        let result = prioritizer.prioritize(
            locations: locations,
            userCoordinate: tokyoStation
        )
        #expect(result[0].location.name == "近い")
        #expect(result[1].location.name == "中間")
        #expect(result[2].location.name == "遠い")
    }

    @Test("全て監視対象になる（20件以下）")
    func allMonitoredUnderLimit() {
        let locations = (0 ..< 5).map { i in
            makeLocationInfo(name: "場所\(i)", lat: 35.0 + Double(i) * 0.01, lon: 139.0)
        }
        let result = prioritizer.prioritize(
            locations: locations,
            userCoordinate: tokyoStation
        )
        let allMonitored = result.allSatisfy(\.isMonitored)
        #expect(allMonitored)
    }

    @Test("20件を超える場合、遠いものは監視対象外")
    func overLimitNotMonitored() {
        let locations = (0 ..< 25).map { i in
            makeLocationInfo(
                name: "場所\(i)",
                lat: 35.0 + Double(i) * 0.001,
                lon: 139.0
            )
        }
        let result = prioritizer.prioritize(
            locations: locations,
            userCoordinate: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0)
        )
        let monitored = result.filter(\.isMonitored)
        let notMonitored = result.filter { !$0.isMonitored }
        #expect(monitored.count == 20)
        #expect(notMonitored.count == 5)
    }

    @Test("アクティブリマインダーなしの場所は除外")
    func excludeInactiveLocations() {
        let locations = [
            makeLocationInfo(name: "アクティブ", lat: 35.6812, lon: 139.7672, activeCount: 2),
            makeLocationInfo(name: "非アクティブ", lat: 35.6812, lon: 139.7673, activeCount: 0),
        ]
        let result = prioritizer.prioritize(
            locations: locations,
            userCoordinate: tokyoStation
        )
        #expect(result.count == 1)
        #expect(result.first?.location.name == "アクティブ")
    }

    @Test("カスタムmaxCountが適用される")
    func customMaxCount() {
        let locations = (0 ..< 10).map { i in
            makeLocationInfo(name: "場所\(i)", lat: 35.0 + Double(i) * 0.001, lon: 139.0)
        }
        let result = prioritizer.prioritize(
            locations: locations,
            userCoordinate: CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0),
            maxCount: 3
        )
        let monitored = result.filter(\.isMonitored)
        #expect(monitored.count == 3)
    }

    // MARK: - monitoredLocationIDs

    @Test("監視対象のIDセットを返す")
    func monitoredIDs() {
        let loc1 = makeLocationInfo(name: "近い", lat: 35.6812, lon: 139.7672)
        let loc2 = makeLocationInfo(name: "遠い", lat: 36.0, lon: 140.0)
        let ids = prioritizer.monitoredLocationIDs(
            locations: [loc1, loc2],
            userCoordinate: tokyoStation,
            maxCount: 1
        )
        #expect(ids.count == 1)
        #expect(ids.contains(loc1.id))
    }

    // MARK: - calculateDiff

    @Test("新規追加の差分計算")
    func diffToAdd() {
        let loc = makeLocationInfo(name: "新規", lat: 35.6812, lon: 139.7672)
        let diff = prioritizer.calculateDiff(
            currentlyMonitored: [],
            locations: [loc],
            userCoordinate: tokyoStation
        )
        #expect(diff.toAdd.count == 1)
        #expect(diff.toRemove.isEmpty)
        #expect(diff.hasChanges)
    }

    @Test("削除の差分計算")
    func diffToRemove() {
        let existingID = UUID()
        let diff = prioritizer.calculateDiff(
            currentlyMonitored: [existingID],
            locations: [], // アクティブな場所なし
            userCoordinate: tokyoStation
        )
        #expect(diff.toAdd.isEmpty)
        #expect(diff.toRemove.count == 1)
        #expect(diff.toRemove.contains(existingID))
    }

    @Test("変更なしの差分計算")
    func diffNoChanges() {
        let loc = makeLocationInfo(name: "同じ", lat: 35.6812, lon: 139.7672)
        let diff = prioritizer.calculateDiff(
            currentlyMonitored: [loc.id],
            locations: [loc],
            userCoordinate: tokyoStation
        )
        #expect(!diff.hasChanges)
    }

    // MARK: - 距離の正確性

    @Test("距離がメートル単位で正しい範囲")
    func distanceAccuracy() {
        let locations = [
            makeLocationInfo(name: "テスト", lat: 35.6812, lon: 139.7672),
        ]
        let result = prioritizer.prioritize(
            locations: locations,
            userCoordinate: tokyoStation
        )
        // 約0.01度の差なので数十メートル程度
        #expect(result.first!.distance < 200)
    }

    // MARK: - maxRegionCount定数

    @Test("最大リージョン数は20")
    func maxRegionCount() {
        #expect(RegionPrioritizer.maxRegionCount == 20)
    }
}
