import Testing
@testable import AsaLifeLogKit

// メインテストは各専用テストファイルに移行済み:
// - EnumTests.swift: 6つのEnum全テスト
// - ModelTests.swift: @Model クラス + SupportingTypes テスト
// - ErrorTests.swift: LifeLogError テスト
// - ServiceTests.swift: InsightsEngine, ExportService, Generator, TimelineService テスト
// - ViewModelTests.swift: 6つのViewModel全テスト
// - Mocks/: MockDataService, MockInsightsEngine, MockLocationService

@Test("AsaLifeLogKit パッケージの基本インポート確認")
func testPackageImport() {
    let entryType = EntryType.manual
    #expect(entryType.rawValue == "manual")
}
