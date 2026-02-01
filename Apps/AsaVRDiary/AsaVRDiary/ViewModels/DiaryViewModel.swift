//
//  DiaryViewModel.swift
//  AsaVRDiary
//
//  日記管理ViewModel
//

import Foundation
import SwiftUI

/// 日記管理ViewModel
@MainActor
@Observable
final class DiaryViewModel {

    // MARK: - Properties

    /// 日記エントリー一覧
    private(set) var entries: [DiaryEntry] = []

    /// フィルタリングされた日記エントリー
    var filteredEntries: [DiaryEntry] {
        var result = entries

        // カテゴリフィルタ
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // 気分フィルタ
        if let mood = selectedMood {
            result = result.filter { $0.mood == mood }
        }

        // お気に入りフィルタ
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        // 検索フィルタ
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    /// 検索テキスト
    var searchText: String = ""

    /// 選択中のカテゴリ
    var selectedCategory: DiaryCategory?

    /// 選択中の気分
    var selectedMood: DiaryMood?

    /// お気に入りのみ表示
    var showFavoritesOnly: Bool = false

    /// 選択中の日記エントリー
    var selectedEntry: DiaryEntry?

    /// 編集中の日記エントリー
    var editingEntry: DiaryEntry?

    /// 新規作成モード
    var isCreatingNew: Bool = false

    /// 読み込み中フラグ
    private(set) var isLoading: Bool = false

    /// エラーメッセージ
    private(set) var errorMessage: String?

    /// データサービス
    private let dataService: DiaryDataService

    // MARK: - Initialization

    init(dataService: DiaryDataService? = nil) {
        self.dataService = dataService ?? DiaryDataService()
    }

    // MARK: - Public Methods

    /// 日記を読み込み
    func loadEntries() {
        isLoading = true
        errorMessage = nil

        entries = dataService.fetchAllEntries()
        isLoading = false
    }

    /// 日記を作成
    func createEntry(
        title: String,
        content: String,
        date: Date = Date(),
        category: DiaryCategory = .daily,
        mood: DiaryMood = .neutral,
        moodIntensity: Int = 3
    ) {
        let entry = DiaryEntry(
            title: title,
            content: content,
            date: date,
            category: category,
            mood: mood,
            moodIntensity: moodIntensity
        )

        dataService.saveEntry(entry)
        loadEntries()
    }

    /// 日記を更新
    func updateEntry(_ entry: DiaryEntry) {
        dataService.updateEntry(entry)
        loadEntries()
    }

    /// 日記を削除
    func deleteEntry(_ entry: DiaryEntry) {
        dataService.deleteEntry(entry)

        // 選択中のエントリーが削除された場合はクリア
        if selectedEntry?.id == entry.id {
            selectedEntry = nil
        }

        loadEntries()
    }

    /// お気に入りを切り替え
    func toggleFavorite(_ entry: DiaryEntry) {
        entry.isFavorite.toggle()
        dataService.updateEntry(entry)
        loadEntries()
    }

    /// フィルタをリセット
    func resetFilters() {
        searchText = ""
        selectedCategory = nil
        selectedMood = nil
        showFavoritesOnly = false
    }

    /// サンプルデータを作成
    func createSampleData() {
        dataService.createSampleData()
        loadEntries()
    }

    /// 日付でグループ化された日記を取得
    func entriesGroupedByDate() -> [(Date, [DiaryEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        return grouped.sorted { $0.key > $1.key }
    }

    /// 月でグループ化された日記を取得
    func entriesGroupedByMonth() -> [(Date, [DiaryEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date))!
        }

        return grouped.sorted { $0.key > $1.key }
    }
}

// MARK: - EditingDiaryState

/// 日記編集状態
struct EditingDiaryState {
    var title: String = ""
    var content: String = ""
    var date: Date = Date()
    var category: DiaryCategory = .daily
    var mood: DiaryMood = .neutral
    var moodIntensity: Int = 3

    /// 既存のエントリーから初期化
    init(from entry: DiaryEntry? = nil) {
        if let entry = entry {
            self.title = entry.title
            self.content = entry.content
            self.date = entry.date
            self.category = entry.category
            self.mood = entry.mood
            self.moodIntensity = entry.moodIntensity
        }
    }

    /// 入力が有効かどうか
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
