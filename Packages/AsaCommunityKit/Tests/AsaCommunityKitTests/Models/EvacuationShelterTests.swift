import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("EvacuationShelter モデルテスト")
struct EvacuationShelterTests {

    @Test("初期化テスト - デフォルト値が正しく設定される")
    func testInitialization() {
        let shelter = EvacuationShelter(
            name: "朝日小学校",
            address: "東京都千代田区1-1-1",
            latitude: 35.68,
            longitude: 139.76,
            capacity: 200
        )
        #expect(shelter.name == "朝日小学校")
        #expect(shelter.capacity == 200)
        #expect(shelter.currentOccupancy == 0)
        #expect(shelter.isOpen == false)
        #expect(shelter.hasWater == false)
    }

    @Test("occupancyRate - 収容率を正しく計算する")
    func testOccupancyRate() {
        let shelter = EvacuationShelter(
            name: "テスト", address: "住所",
            latitude: 0, longitude: 0, capacity: 100
        )
        shelter.currentOccupancy = 50
        #expect(abs(shelter.occupancyRate - 0.5) < 0.0001)

        shelter.currentOccupancy = 100
        #expect(abs(shelter.occupancyRate - 1.0) < 0.0001)
    }

    @Test("occupancyRate - 定員0の場合は0.0を返す")
    func testOccupancyRateZeroCapacity() {
        let shelter = EvacuationShelter(
            name: "テスト", address: "住所",
            latitude: 0, longitude: 0, capacity: 0
        )
        #expect(shelter.occupancyRate == 0.0)
    }

    @Test("remainingCapacity - 残り収容可能人数を正しく計算する")
    func testRemainingCapacity() {
        let shelter = EvacuationShelter(
            name: "テスト", address: "住所",
            latitude: 0, longitude: 0, capacity: 200
        )
        shelter.currentOccupancy = 80
        #expect(shelter.remainingCapacity == 120)

        shelter.currentOccupancy = 200
        #expect(shelter.remainingCapacity == 0)
    }

    @Test("remainingCapacity - 超過時は0を返す")
    func testRemainingCapacityOverflow() {
        let shelter = EvacuationShelter(
            name: "テスト", address: "住所",
            latitude: 0, longitude: 0, capacity: 50
        )
        shelter.currentOccupancy = 60
        #expect(shelter.remainingCapacity == 0)
    }

    @Test("facilitiesText - 設備一覧テキストが正しく表示される")
    func testFacilitiesText() {
        let shelter = EvacuationShelter(
            name: "テスト", address: "住所",
            latitude: 0, longitude: 0, capacity: 100,
            hasWater: true, hasFood: true, hasMedical: false, hasElectricity: true
        )
        #expect(shelter.facilitiesText == "給水・食料・電源")
    }

    @Test("facilitiesText - 全設備ありの場合")
    func testFacilitiesTextAll() {
        let shelter = EvacuationShelter(
            name: "テスト", address: "住所",
            latitude: 0, longitude: 0, capacity: 100,
            hasWater: true, hasFood: true, hasMedical: true, hasElectricity: true
        )
        #expect(shelter.facilitiesText == "給水・食料・医療・電源")
    }

    @Test("facilitiesText - 設備なしの場合は「情報なし」を返す")
    func testFacilitiesTextNone() {
        let shelter = EvacuationShelter(
            name: "テスト", address: "住所",
            latitude: 0, longitude: 0, capacity: 100
        )
        #expect(shelter.facilitiesText == "情報なし")
    }
}
