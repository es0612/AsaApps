import Testing
import Foundation
import SwiftUI
@testable import AsaPapaHub

// MARK: - AsaPapaHub テスト

struct AsaPapaHubTests {
    // MARK: - PapaHubWidgetData テスト

    @Test("WidgetData プレースホルダーが有効な値を持つ")
    func testWidgetDataPlaceholder() {
        let placeholder = PapaHubWidgetData.placeholder
        #expect(placeholder.morningScore > 0)
        #expect(placeholder.stepsCount > 0)
        #expect(placeholder.sleepHours > 0)
        #expect(!placeholder.domainScores.isEmpty)
    }

    @Test("WidgetData のエンコード・デコードが正常に動作する")
    func testWidgetDataCodable() throws {
        let data = PapaHubWidgetData(
            morningScore: 85,
            stepsCount: 8500,
            sleepHours: 7.2,
            overallProgress: 0.85,
            briefingSummary: "テストサマリー"
        )

        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(PapaHubWidgetData.self, from: encoded)

        #expect(decoded.morningScore == 85)
        #expect(decoded.stepsCount == 8500)
        #expect(abs(decoded.sleepHours - 7.2) < 0.0001)
        #expect(decoded.briefingSummary == "テストサマリー")
    }

    // MARK: - SharedDefaults テスト

    @Test("SharedDefaults の suiteName が正しい")
    func testSharedDefaultsSuiteName() {
        #expect(SharedDefaults.suiteName == "group.com.asapapa.apps.asapapahub")
    }

    // MARK: - Color Hex テスト

    @Test("Color(hex:) が正しく初期化される")
    func testColorHexInit() {
        // 正常なHEX値で初期化できることを確認
        let _ = SwiftUI.Color(hex: "#FF9500")
        let _ = SwiftUI.Color(hex: "007AFF")
        let _ = SwiftUI.Color(hex: "#C68C53")
    }

    // MARK: - DomainScore テスト

    @Test("DomainScore の id がドメイン名と一致する")
    func testDomainScoreId() {
        let score = DomainScore(domain: "朝活", icon: "sunrise.fill", score: 85)
        #expect(score.id == "朝活")
        #expect(score.score == 85)
    }

    // MARK: - RoutineItemData テスト

    @Test("RoutineItemData の id がタイトルと一致する")
    func testRoutineItemDataId() {
        let item = RoutineItemData(title: "早起き", icon: "alarm.fill", isCompleted: true)
        #expect(item.id == "早起き")
        #expect(item.isCompleted == true)
    }
}
