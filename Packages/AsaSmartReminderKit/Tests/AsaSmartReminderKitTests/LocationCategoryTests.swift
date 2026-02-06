import Foundation
import Testing
@testable import AsaSmartReminderKit

// MARK: - LocationCategory テスト

@Suite("LocationCategory")
struct LocationCategoryTests {

    // MARK: - 全カテゴリ一覧

    @Test("全カテゴリが9種類存在する")
    func allCasesCount() {
        #expect(LocationCategory.allCases.count == 9)
    }

    // MARK: - 表示名

    @Test("各カテゴリに日本語表示名がある",
          arguments: LocationCategory.allCases)
    func displayNameNotEmpty(category: LocationCategory) {
        #expect(!category.displayName.isEmpty)
    }

    @Test("自宅カテゴリの表示名")
    func homeDisplayName() {
        #expect(LocationCategory.home.displayName == "自宅")
    }

    @Test("職場カテゴリの表示名")
    func workDisplayName() {
        #expect(LocationCategory.work.displayName == "職場")
    }

    @Test("学校カテゴリの表示名")
    func schoolDisplayName() {
        #expect(LocationCategory.school.displayName == "学校")
    }

    @Test("スーパーカテゴリの表示名")
    func supermarketDisplayName() {
        #expect(LocationCategory.supermarket.displayName == "スーパー")
    }

    @Test("駅カテゴリの表示名")
    func stationDisplayName() {
        #expect(LocationCategory.station.displayName == "駅")
    }

    @Test("カスタムカテゴリの表示名")
    func customDisplayName() {
        #expect(LocationCategory.custom.displayName == "カスタム")
    }

    // MARK: - SFSymbol名

    @Test("各カテゴリにSFSymbol名がある",
          arguments: LocationCategory.allCases)
    func systemImageNameNotEmpty(category: LocationCategory) {
        #expect(!category.systemImageName.isEmpty)
    }

    @Test("自宅のSFSymbol")
    func homeSystemImage() {
        #expect(LocationCategory.home.systemImageName == "house.fill")
    }

    // MARK: - デフォルト半径

    @Test("各カテゴリのデフォルト半径が正の値",
          arguments: LocationCategory.allCases)
    func defaultRadiusPositive(category: LocationCategory) {
        #expect(category.defaultRadius > 0)
    }

    @Test("自宅のデフォルト半径は50m")
    func homeDefaultRadius() {
        #expect(LocationCategory.home.defaultRadius == 50)
    }

    @Test("職場のデフォルト半径は100m")
    func workDefaultRadius() {
        #expect(LocationCategory.work.defaultRadius == 100)
    }

    @Test("カスタムのデフォルト半径は100m")
    func customDefaultRadius() {
        #expect(LocationCategory.custom.defaultRadius == 100)
    }

    // MARK: - Codable

    @Test("Codableエンコード・デコードの往復")
    func codableRoundtrip() throws {
        let original = LocationCategory.supermarket
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LocationCategory.self, from: data)
        #expect(decoded == original)
    }

    @Test("全カテゴリのCodable往復",
          arguments: LocationCategory.allCases)
    func codableRoundtripAll(category: LocationCategory) throws {
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(LocationCategory.self, from: data)
        #expect(decoded == category)
    }

    // MARK: - rawValue

    @Test("rawValueからの生成")
    func rawValueInit() {
        #expect(LocationCategory(rawValue: "home") == .home)
        #expect(LocationCategory(rawValue: "unknown") == nil)
    }
}
