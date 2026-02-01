//
//  DiaryEntityRendererTests.swift
//  AsaVRDiaryTests
//
//  DiaryEntityRendererのテスト
//

import Testing
import Foundation
import simd
@testable import AsaVRDiary

@Suite("DiaryEntityRenderer Tests")
struct DiaryEntityRendererTests {

    // MARK: - Timeline Position Tests

    @Test("タイムライン位置計算テスト - 同じ日")
    func testTimelinePositionSameDay() {
        let now = Date()
        let entry = DiaryEntry(title: "テスト", content: "", date: now)

        let position = DiaryEntityRenderer.calculateTimelinePosition(
            for: entry,
            referenceDate: now,
            index: 0
        )

        // 同じ日なのでX座標は0
        #expect(position.x == 0.0)
    }

    @Test("タイムライン位置計算テスト - 1日後")
    func testTimelinePositionNextDay() {
        let calendar = Calendar.current
        let referenceDate = Date()
        let nextDay = calendar.date(byAdding: .day, value: 1, to: referenceDate)!

        let entry = DiaryEntry(title: "テスト", content: "", date: nextDay)

        let position = DiaryEntityRenderer.calculateTimelinePosition(
            for: entry,
            referenceDate: referenceDate,
            index: 0
        )

        // 1日後なのでX座標は0.2
        #expect(position.x == 0.2)
    }

    @Test("タイムライン位置計算テスト - Y座標は気分で決まる")
    func testTimelinePositionMoodYOffset() {
        let now = Date()

        let happyEntry = DiaryEntry(title: "幸せ", content: "", date: now, mood: .veryHappy, moodIntensity: 5)
        let sadEntry = DiaryEntry(title: "悲しい", content: "", date: now, mood: .verySad, moodIntensity: 5)

        let happyPosition = DiaryEntityRenderer.calculateTimelinePosition(
            for: happyEntry,
            referenceDate: now,
            index: 0
        )

        let sadPosition = DiaryEntityRenderer.calculateTimelinePosition(
            for: sadEntry,
            referenceDate: now,
            index: 0
        )

        // 幸せな気分は上、悲しい気分は下
        #expect(happyPosition.y > sadPosition.y)
    }

    @Test("タイムライン位置計算テスト - Z座標はカテゴリで決まる")
    func testTimelinePositionCategoryZOffset() {
        let now = Date()

        let dailyEntry = DiaryEntry(title: "日常", content: "", date: now, category: .daily)
        let workEntry = DiaryEntry(title: "仕事", content: "", date: now, category: .work)

        let dailyPosition = DiaryEntityRenderer.calculateTimelinePosition(
            for: dailyEntry,
            referenceDate: now,
            index: 0
        )

        let workPosition = DiaryEntityRenderer.calculateTimelinePosition(
            for: workEntry,
            referenceDate: now,
            index: 0
        )

        // 異なるカテゴリは異なるZ座標
        #expect(dailyPosition.z != workPosition.z)
    }

    // MARK: - Grid Position Tests

    @Test("グリッド位置計算テスト - 最初の要素")
    func testGridPositionFirst() {
        let position = DiaryEntityRenderer.calculateGridPosition(index: 0)

        // 最初の要素は左上
        #expect(position.z == -0.5) // カメラから0.5m前方
    }

    @Test("グリッド位置計算テスト - 行列配置")
    func testGridPositionRowColumn() {
        let position0 = DiaryEntityRenderer.calculateGridPosition(index: 0, columns: 4)
        let position1 = DiaryEntityRenderer.calculateGridPosition(index: 1, columns: 4)
        let position4 = DiaryEntityRenderer.calculateGridPosition(index: 4, columns: 4) // 2行目最初

        // 同じ行は同じY座標
        #expect(position0.y == position1.y)

        // 次の行は異なるY座標（下に移動）
        #expect(position4.y < position0.y)

        // 隣は異なるX座標
        #expect(position1.x > position0.x)
    }

    @Test("グリッド位置計算テスト - カラム数による配置")
    func testGridPositionColumnCount() {
        let position3Col3 = DiaryEntityRenderer.calculateGridPosition(index: 3, columns: 3)
        let position3Col4 = DiaryEntityRenderer.calculateGridPosition(index: 3, columns: 4)

        // 3列の場合、index 3は2行目
        // 4列の場合、index 3は1行目
        #expect(position3Col3.y < position3Col4.y)
    }
}

// MARK: - DiaryCardComponent Tests

@Suite("DiaryCardComponent Tests")
struct DiaryCardComponentTests {

    @Test("初期化テスト")
    func testInitialization() {
        let id = UUID()
        let component = DiaryCardComponent(entryId: id)

        #expect(component.entryId == id)
        #expect(component.isFlipped == false)
        #expect(component.isSelected == false)
    }

    @Test("フリップ状態変更テスト")
    func testFlipState() {
        let id = UUID()
        var component = DiaryCardComponent(entryId: id)

        #expect(component.isFlipped == false)

        component.isFlipped = true
        #expect(component.isFlipped == true)

        component.isFlipped.toggle()
        #expect(component.isFlipped == false)
    }

    @Test("選択状態変更テスト")
    func testSelectionState() {
        let id = UUID()
        var component = DiaryCardComponent(entryId: id)

        #expect(component.isSelected == false)

        component.isSelected = true
        #expect(component.isSelected == true)
    }
}
