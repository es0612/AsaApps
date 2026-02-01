//
//  DiaryEntryTests.swift
//  AsaVRDiaryTests
//
//  DiaryEntryモデルのテスト
//

import Testing
import Foundation
@testable import AsaVRDiary

@Suite("DiaryEntry Tests")
struct DiaryEntryTests {

    // MARK: - Initialization Tests

    @Test("DiaryEntry初期化テスト - デフォルト値")
    func testDefaultInitialization() {
        let entry = DiaryEntry(title: "テスト", content: "内容")

        #expect(entry.title == "テスト")
        #expect(entry.content == "内容")
        #expect(entry.category == .daily)
        #expect(entry.mood == .neutral)
        #expect(entry.moodIntensity == 3)
        #expect(entry.isFavorite == false)
        #expect(entry.vrPositionX == nil)
        #expect(entry.vrPositionY == nil)
        #expect(entry.vrPositionZ == nil)
    }

    @Test("DiaryEntry初期化テスト - カスタム値")
    func testCustomInitialization() {
        let entry = DiaryEntry(
            title: "カスタム",
            content: "カスタム内容",
            category: .family,
            mood: .happy,
            moodIntensity: 4,
            isFavorite: true
        )

        #expect(entry.title == "カスタム")
        #expect(entry.content == "カスタム内容")
        #expect(entry.category == .family)
        #expect(entry.mood == .happy)
        #expect(entry.moodIntensity == 4)
        #expect(entry.isFavorite == true)
    }

    @Test("moodIntensityの範囲制限テスト - 最小値")
    func testMoodIntensityMinValue() {
        let entry = DiaryEntry(title: "テスト", content: "", moodIntensity: -5)
        #expect(entry.moodIntensity == 1)
    }

    @Test("moodIntensityの範囲制限テスト - 最大値")
    func testMoodIntensityMaxValue() {
        let entry = DiaryEntry(title: "テスト", content: "", moodIntensity: 100)
        #expect(entry.moodIntensity == 5)
    }

    // MARK: - Computed Properties Tests

    @Test("contentPreviewテスト - 短いコンテンツ")
    func testContentPreviewShort() {
        let entry = DiaryEntry(title: "テスト", content: "短い内容")
        #expect(entry.contentPreview == "短い内容")
    }

    @Test("contentPreviewテスト - 長いコンテンツ")
    func testContentPreviewLong() {
        let longContent = String(repeating: "あ", count: 150)
        let entry = DiaryEntry(title: "テスト", content: longContent)

        #expect(entry.contentPreview.count == 103) // 100文字 + "..."
        #expect(entry.contentPreview.hasSuffix("..."))
    }

    @Test("hasCustomVRPositionテスト - 未設定")
    func testHasCustomVRPositionFalse() {
        let entry = DiaryEntry(title: "テスト", content: "")
        #expect(entry.hasCustomVRPosition == false)
    }

    @Test("hasCustomVRPositionテスト - 設定済み")
    func testHasCustomVRPositionTrue() {
        let entry = DiaryEntry(title: "テスト", content: "")
        entry.setVRPosition(x: 1.0, y: 2.0, z: 3.0)
        #expect(entry.hasCustomVRPosition == true)
    }

    @Test("formattedDateテスト")
    func testFormattedDate() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 3, day: 15)
        let date = calendar.date(from: components)!

        let entry = DiaryEntry(title: "テスト", content: "", date: date)
        #expect(entry.formattedDate == "2024年3月15日")
    }

    // MARK: - Method Tests

    @Test("setVRPositionテスト")
    func testSetVRPosition() {
        let entry = DiaryEntry(title: "テスト", content: "")
        entry.setVRPosition(x: 1.5, y: 2.5, z: 3.5)

        #expect(entry.vrPositionX == 1.5)
        #expect(entry.vrPositionY == 2.5)
        #expect(entry.vrPositionZ == 3.5)
    }

    @Test("resetVRPositionテスト")
    func testResetVRPosition() {
        let entry = DiaryEntry(title: "テスト", content: "")
        entry.setVRPosition(x: 1.0, y: 2.0, z: 3.0)
        entry.resetVRPosition()

        #expect(entry.vrPositionX == nil)
        #expect(entry.vrPositionY == nil)
        #expect(entry.vrPositionZ == nil)
    }

    @Test("touchテスト - 更新日時が変更される")
    func testTouch() async throws {
        let entry = DiaryEntry(title: "テスト", content: "")
        let originalUpdatedAt = entry.updatedAt

        // 少し待機
        try await Task.sleep(for: .milliseconds(10))

        entry.touch()

        #expect(entry.updatedAt > originalUpdatedAt)
    }

    // MARK: - Category Tests

    @Test("カテゴリ設定と取得テスト")
    func testCategorySetGet() {
        let entry = DiaryEntry(title: "テスト", content: "")

        entry.category = .work
        #expect(entry.category == .work)
        #expect(entry.categoryRawValue == "work")

        entry.category = .travel
        #expect(entry.category == .travel)
        #expect(entry.categoryRawValue == "travel")
    }

    // MARK: - Mood Tests

    @Test("気分設定と取得テスト")
    func testMoodSetGet() {
        let entry = DiaryEntry(title: "テスト", content: "")

        entry.mood = .veryHappy
        #expect(entry.mood == .veryHappy)
        #expect(entry.moodRawValue == "veryHappy")

        entry.mood = .anxious
        #expect(entry.mood == .anxious)
        #expect(entry.moodRawValue == "anxious")
    }

    // MARK: - Equatable Tests

    @Test("Equatableテスト - 同じID")
    func testEquatableSameId() {
        let id = UUID()
        let entry1 = DiaryEntry(id: id, title: "テスト1", content: "内容1")
        let entry2 = DiaryEntry(id: id, title: "テスト2", content: "内容2")

        #expect(entry1 == entry2)
    }

    @Test("Equatableテスト - 異なるID")
    func testEquatableDifferentId() {
        let entry1 = DiaryEntry(title: "テスト", content: "内容")
        let entry2 = DiaryEntry(title: "テスト", content: "内容")

        #expect(entry1 != entry2)
    }
}
