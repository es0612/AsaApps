//
//  EventViewModel.swift
//  AsaSmartAlarm
//
//  イベント管理のViewModel
//

import Foundation

// MARK: - イベントViewModel

/// イベントの管理を行うViewModel
@MainActor
@Observable
final class EventViewModel {
    // MARK: - Properties

    private(set) var events: [CalendarEvent] = []
    private(set) var upcomingEvents: [CalendarEvent] = []
    private(set) var tomorrowMorningEvents: [CalendarEvent] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    // シート表示
    var showingAddEvent: Bool = false
    var selectedEvent: CalendarEvent?

    // Service
    private var dataService: DataService?

    // MARK: - Computed Properties

    /// 今後のイベント数
    var upcomingEventCount: Int {
        upcomingEvents.count
    }

    /// 明日の朝のイベントがあるかどうか
    var hasTomorrowMorningEvents: Bool {
        !tomorrowMorningEvents.isEmpty
    }

    /// 明日の最も早いイベント
    var earliestTomorrowEvent: CalendarEvent? {
        tomorrowMorningEvents.first
    }

    /// セクション別にグループ化されたイベント
    var eventsBySection: [(title: String, events: [CalendarEvent])] {
        let calendar = Calendar.current
        let now = Date()

        var sections: [(title: String, events: [CalendarEvent])] = []

        // 今日のイベント
        let todayEvents = events.filter { calendar.isDateInToday($0.startTime) }
        if !todayEvents.isEmpty {
            sections.append((title: "今日", events: todayEvents))
        }

        // 明日のイベント
        let tomorrowEvents = events.filter { calendar.isDateInTomorrow($0.startTime) }
        if !tomorrowEvents.isEmpty {
            sections.append((title: "明日", events: tomorrowEvents))
        }

        // それ以降のイベント
        let laterEvents = events.filter {
            !calendar.isDateInToday($0.startTime) &&
            !calendar.isDateInTomorrow($0.startTime) &&
            $0.startTime > now
        }
        if !laterEvents.isEmpty {
            sections.append((title: "今後の予定", events: laterEvents))
        }

        return sections
    }

    // MARK: - Initializer

    init() {}

    // MARK: - Setup

    /// DataServiceを設定
    func setup(dataService: DataService) {
        self.dataService = dataService
        Task {
            await loadData()
        }
    }

    // MARK: - Data Operations

    /// データをロード
    func loadData() async {
        guard let dataService = dataService else { return }

        isLoading = true
        errorMessage = nil

        do {
            events = try dataService.fetchAllEvents()
            upcomingEvents = try dataService.fetchUpcomingEvents(days: 7)
            tomorrowMorningEvents = try dataService.fetchTomorrowMorningEvents()

            print("📆 イベントをロード: \(events.count)件")
        } catch {
            errorMessage = "データの読み込みに失敗しました"
            print("📆 ロードエラー: \(error)")
        }

        isLoading = false
    }

    /// イベントを追加
    func addEvent(
        title: String,
        startTime: Date,
        endTime: Date? = nil,
        description: String? = nil,
        location: String? = nil,
        preparationMinutes: Int = 30,
        travelMinutes: Int = 30,
        priority: EventPriority = .medium,
        isAllDay: Bool = false
    ) async {
        guard let dataService = dataService else { return }

        do {
            let event = try dataService.createEvent(
                title: title,
                startTime: startTime,
                endTime: endTime,
                description: description,
                location: location,
                preparationMinutes: preparationMinutes,
                travelMinutes: travelMinutes,
                priority: priority,
                isAllDay: isAllDay
            )

            events.append(event)
            events.sort { $0.startTime < $1.startTime }

            // リストを更新
            await loadData()

            print("📆 イベント追加完了: \(event.title)")
        } catch {
            errorMessage = "イベントの追加に失敗しました"
            print("📆 追加エラー: \(error)")
        }
    }

    /// イベントを更新
    func updateEvent(_ event: CalendarEvent) async {
        guard let dataService = dataService else { return }

        do {
            try dataService.updateEvent(event)
            await loadData()
            print("📆 イベント更新完了: \(event.title)")
        } catch {
            errorMessage = "イベントの更新に失敗しました"
            print("📆 更新エラー: \(error)")
        }
    }

    /// イベントを削除
    func deleteEvent(_ event: CalendarEvent) async {
        guard let dataService = dataService else { return }

        do {
            try dataService.deleteEvent(event)
            events.removeAll { $0.id == event.id }
            await loadData()
            print("📆 イベント削除完了")
        } catch {
            errorMessage = "イベントの削除に失敗しました"
            print("📆 削除エラー: \(error)")
        }
    }

    /// イベントを複数削除
    func deleteEvents(at offsets: IndexSet, in sectionEvents: [CalendarEvent]) async {
        let eventsToDelete = offsets.map { sectionEvents[$0] }
        for event in eventsToDelete {
            await deleteEvent(event)
        }
    }

    // MARK: - Utility

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Preview Support

extension EventViewModel {
    /// プレビュー用のViewModel
    static var preview: EventViewModel {
        let viewModel = EventViewModel()
        viewModel.setup(dataService: .preview)
        return viewModel
    }
}
