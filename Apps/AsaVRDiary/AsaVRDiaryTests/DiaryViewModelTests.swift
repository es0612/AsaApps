//
//  DiaryViewModelTests.swift
//  AsaVRDiaryTests
//
//  DiaryViewModelのテスト
//

import Testing
import Foundation
@testable import AsaVRDiary

@Suite("DiaryViewModel Tests")
@MainActor
struct DiaryViewModelTests {

    // MARK: - Setup

    func createTestViewModel() -> DiaryViewModel {
        let service = DiaryDataService(inMemory: true)
        return DiaryViewModel(dataService: service)
    }

    // MARK: - Initialization Tests

    @Test("初期化テスト")
    func testInitialization() {
        let viewModel = createTestViewModel()

        #expect(viewModel.entries.isEmpty)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedCategory == nil)
        #expect(viewModel.selectedMood == nil)
        #expect(viewModel.showFavoritesOnly == false)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Create Entry Tests

    @Test("日記作成テスト")
    func testCreateEntry() {
        let viewModel = createTestViewModel()

        viewModel.createEntry(
            title: "テスト日記",
            content: "テスト内容",
            category: .daily,
            mood: .happy,
            moodIntensity: 4
        )

        #expect(viewModel.entries.count == 1)
        #expect(viewModel.entries.first?.title == "テスト日記")
        #expect(viewModel.entries.first?.content == "テスト内容")
        #expect(viewModel.entries.first?.category == .daily)
        #expect(viewModel.entries.first?.mood == .happy)
        #expect(viewModel.entries.first?.moodIntensity == 4)
    }

    // MARK: - Delete Entry Tests

    @Test("日記削除テスト")
    func testDeleteEntry() {
        let viewModel = createTestViewModel()

        viewModel.createEntry(title: "削除テスト", content: "")
        #expect(viewModel.entries.count == 1)

        let entry = viewModel.entries.first!
        viewModel.deleteEntry(entry)

        #expect(viewModel.entries.isEmpty)
    }

    // MARK: - Toggle Favorite Tests

    @Test("お気に入り切り替えテスト")
    func testToggleFavorite() {
        let viewModel = createTestViewModel()

        viewModel.createEntry(title: "お気に入りテスト", content: "")
        let entry = viewModel.entries.first!

        #expect(entry.isFavorite == false)

        viewModel.toggleFavorite(entry)
        #expect(entry.isFavorite == true)

        viewModel.toggleFavorite(entry)
        #expect(entry.isFavorite == false)
    }

    // MARK: - Filter Tests

    @Test("カテゴリフィルターテスト")
    func testCategoryFilter() {
        let viewModel = createTestViewModel()

        viewModel.createEntry(title: "日常1", content: "", category: .daily)
        viewModel.createEntry(title: "仕事1", content: "", category: .work)
        viewModel.createEntry(title: "日常2", content: "", category: .daily)

        #expect(viewModel.filteredEntries.count == 3)

        viewModel.selectedCategory = .daily
        #expect(viewModel.filteredEntries.count == 2)
        #expect(viewModel.filteredEntries.allSatisfy { $0.category == .daily })

        viewModel.selectedCategory = .work
        #expect(viewModel.filteredEntries.count == 1)
    }

    @Test("気分フィルターテスト")
    func testMoodFilter() {
        let viewModel = createTestViewModel()

        viewModel.createEntry(title: "幸せ1", content: "", mood: .happy)
        viewModel.createEntry(title: "悲しい1", content: "", mood: .sad)
        viewModel.createEntry(title: "幸せ2", content: "", mood: .happy)

        viewModel.selectedMood = .happy
        #expect(viewModel.filteredEntries.count == 2)
        #expect(viewModel.filteredEntries.allSatisfy { $0.mood == .happy })
    }

    @Test("お気に入りフィルターテスト")
    func testFavoritesFilter() {
        let viewModel = createTestViewModel()

        viewModel.createEntry(title: "通常", content: "")
        viewModel.createEntry(title: "お気に入り", content: "")

        // お気に入りをトグル
        if let favoriteEntry = viewModel.entries.first(where: { $0.title == "お気に入り" }) {
            viewModel.toggleFavorite(favoriteEntry)
        }

        viewModel.showFavoritesOnly = true
        #expect(viewModel.filteredEntries.count == 1)
        #expect(viewModel.filteredEntries.first?.title == "お気に入り")
    }

    @Test("検索フィルターテスト")
    func testSearchFilter() {
        let viewModel = createTestViewModel()

        viewModel.createEntry(title: "朝活記録", content: "今日も5時起き")
        viewModel.createEntry(title: "仕事メモ", content: "会議の内容")
        viewModel.createEntry(title: "朝のランニング", content: "公園を走った")

        viewModel.searchText = "朝"
        #expect(viewModel.filteredEntries.count == 2)
    }

    // MARK: - Reset Filters Tests

    @Test("フィルターリセットテスト")
    func testResetFilters() {
        let viewModel = createTestViewModel()

        viewModel.searchText = "テスト"
        viewModel.selectedCategory = .work
        viewModel.selectedMood = .happy
        viewModel.showFavoritesOnly = true

        viewModel.resetFilters()

        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedCategory == nil)
        #expect(viewModel.selectedMood == nil)
        #expect(viewModel.showFavoritesOnly == false)
    }

    // MARK: - Grouped Entries Tests

    @Test("日付グループ化テスト")
    func testEntriesGroupedByDate() {
        let viewModel = createTestViewModel()
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        viewModel.createEntry(title: "今日1", content: "", date: today)
        viewModel.createEntry(title: "今日2", content: "", date: today)
        viewModel.createEntry(title: "昨日", content: "", date: yesterday)

        let grouped = viewModel.entriesGroupedByDate()

        #expect(grouped.count == 2)
    }

    // MARK: - Sample Data Tests

    @Test("サンプルデータ作成テスト")
    func testCreateSampleData() {
        let viewModel = createTestViewModel()

        #expect(viewModel.entries.isEmpty)

        viewModel.createSampleData()

        #expect(!viewModel.entries.isEmpty)
        #expect(viewModel.entries.count >= 5)
    }
}

// MARK: - EditingDiaryState Tests

@Suite("EditingDiaryState Tests")
struct EditingDiaryStateTests {

    @Test("デフォルト初期化テスト")
    func testDefaultInitialization() {
        let state = EditingDiaryState()

        #expect(state.title.isEmpty)
        #expect(state.content.isEmpty)
        #expect(state.category == .daily)
        #expect(state.mood == .neutral)
        #expect(state.moodIntensity == 3)
    }

    @Test("既存エントリーからの初期化テスト")
    func testInitFromEntry() {
        let entry = DiaryEntry(
            title: "テスト",
            content: "内容",
            category: .work,
            mood: .happy,
            moodIntensity: 5
        )

        let state = EditingDiaryState(from: entry)

        #expect(state.title == "テスト")
        #expect(state.content == "内容")
        #expect(state.category == .work)
        #expect(state.mood == .happy)
        #expect(state.moodIntensity == 5)
    }

    @Test("isValidテスト - 有効なタイトル")
    func testIsValidWithTitle() {
        var state = EditingDiaryState()
        state.title = "有効なタイトル"

        #expect(state.isValid == true)
    }

    @Test("isValidテスト - 空のタイトル")
    func testIsValidEmptyTitle() {
        let state = EditingDiaryState()

        #expect(state.isValid == false)
    }

    @Test("isValidテスト - 空白のみのタイトル")
    func testIsValidWhitespaceTitle() {
        var state = EditingDiaryState()
        state.title = "   "

        #expect(state.isValid == false)
    }
}
