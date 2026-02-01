//
//  DiaryCategoryTests.swift
//  AsaVRDiaryTests
//
//  DiaryCategoryのテスト
//

import Testing
import SwiftUI
@testable import AsaVRDiary

@Suite("DiaryCategory Tests")
struct DiaryCategoryTests {

    // MARK: - Display Name Tests

    @Test("displayNameテスト - すべてのカテゴリ")
    func testDisplayNames() {
        #expect(DiaryCategory.daily.displayName == "日常")
        #expect(DiaryCategory.work.displayName == "仕事")
        #expect(DiaryCategory.family.displayName == "家族")
        #expect(DiaryCategory.hobby.displayName == "趣味")
        #expect(DiaryCategory.travel.displayName == "旅行")
        #expect(DiaryCategory.health.displayName == "健康")
        #expect(DiaryCategory.learning.displayName == "学び")
        #expect(DiaryCategory.special.displayName == "特別な日")
        #expect(DiaryCategory.other.displayName == "その他")
    }

    // MARK: - Icon Tests

    @Test("iconテスト - すべてのカテゴリ")
    func testIcons() {
        #expect(DiaryCategory.daily.icon == "sun.max.fill")
        #expect(DiaryCategory.work.icon == "briefcase.fill")
        #expect(DiaryCategory.family.icon == "house.fill")
        #expect(DiaryCategory.hobby.icon == "paintpalette.fill")
        #expect(DiaryCategory.travel.icon == "airplane")
        #expect(DiaryCategory.health.icon == "heart.fill")
        #expect(DiaryCategory.learning.icon == "book.fill")
        #expect(DiaryCategory.special.icon == "star.fill")
        #expect(DiaryCategory.other.icon == "ellipsis.circle.fill")
    }

    // MARK: - VR Z Offset Tests

    @Test("vrZOffsetテスト - 各カテゴリに固有の値")
    func testVRZOffsets() {
        let offsets = DiaryCategory.allCases.map { $0.vrZOffset }
        let uniqueOffsets = Set(offsets)

        // すべてのカテゴリが異なるZ座標を持つ
        #expect(uniqueOffsets.count == DiaryCategory.allCases.count)
    }

    @Test("vrZOffsetテスト - 適切な範囲")
    func testVRZOffsetsRange() {
        for category in DiaryCategory.allCases {
            let offset = category.vrZOffset
            #expect(offset >= -1.5 && offset <= 1.5)
        }
    }

    // MARK: - Raw Value Tests

    @Test("rawValueからの初期化テスト")
    func testRawValueInitialization() {
        #expect(DiaryCategory(rawValue: "daily") == .daily)
        #expect(DiaryCategory(rawValue: "work") == .work)
        #expect(DiaryCategory(rawValue: "invalid") == nil)
    }

    // MARK: - All Cases Tests

    @Test("allCasesテスト - 9カテゴリ")
    func testAllCasesCount() {
        #expect(DiaryCategory.allCases.count == 9)
    }

    // MARK: - Codable Tests

    @Test("Codableテスト")
    func testCodable() throws {
        let original = DiaryCategory.family
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(DiaryCategory.self, from: data)

        #expect(decoded == original)
    }
}
