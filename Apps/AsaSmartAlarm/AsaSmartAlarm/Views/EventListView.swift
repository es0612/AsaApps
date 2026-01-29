//
//  EventListView.swift
//  AsaSmartAlarm
//
//  イベント一覧画面
//

import SwiftUI

// MARK: - イベント一覧ビュー

/// イベントの一覧を表示する画面
struct EventListView: View {
    // MARK: - Properties

    var viewModel: EventViewModel

    // MARK: - Body

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.events.isEmpty {
                    EmptyEventView()
                } else {
                    List {
                        ForEach(viewModel.eventsBySection, id: \.title) { section in
                            Section(section.title) {
                                ForEach(section.events) { event in
                                    EventRowView(event: event)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            viewModel.selectedEvent = event
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task {
                                                    await viewModel.deleteEvent(event)
                                                }
                                            } label: {
                                                Label("削除", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("予定")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $bindableViewModel.showingAddEvent) {
                AddEventView(viewModel: viewModel)
            }
            .sheet(item: $bindableViewModel.selectedEvent) { event in
                EventDetailView(
                    event: event,
                    onSave: { updatedEvent in
                        Task {
                            await viewModel.updateEvent(updatedEvent)
                        }
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteEvent(event)
                        }
                    }
                )
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - イベント行ビュー

struct EventRowView: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            // 優先度インジケーター
            Rectangle()
                .fill(priorityColor)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 4) {
                // タイトル
                Text(event.title)
                    .font(.headline)

                // 日時
                HStack(spacing: 8) {
                    Label(event.fullDateTimeString, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let location = event.location, !location.isEmpty {
                        Label(location, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // 準備時間
                Text("準備: \(event.preparationMinutes)分 + 移動: \(event.travelMinutes)分")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // 朝イベントバッジ
            if event.isMorningEvent && !event.isAllDay {
                Image(systemName: "sunrise.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch event.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
}

// MARK: - 空のイベントビュー

private struct EmptyEventView: View {
    var body: some View {
        ContentUnavailableView {
            Label("予定がありません", systemImage: "calendar")
        } description: {
            Text("右上の＋ボタンから予定を追加してください")
        }
    }
}

// MARK: - イベント詳細ビュー

struct EventDetailView: View {
    let event: CalendarEvent
    let onSave: (CalendarEvent) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var startTime: Date
    @State private var location: String
    @State private var preparationMinutes: Int
    @State private var travelMinutes: Int
    @State private var priority: EventPriority
    @State private var isAllDay: Bool
    @State private var showingDeleteConfirmation: Bool = false

    init(
        event: CalendarEvent,
        onSave: @escaping (CalendarEvent) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.event = event
        self.onSave = onSave
        self.onDelete = onDelete

        _title = State(initialValue: event.title)
        _startTime = State(initialValue: event.startTime)
        _location = State(initialValue: event.location ?? "")
        _preparationMinutes = State(initialValue: event.preparationMinutes)
        _travelMinutes = State(initialValue: event.travelMinutes)
        _priority = State(initialValue: event.priority)
        _isAllDay = State(initialValue: event.isAllDay)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("タイトル", text: $title)

                    Toggle("終日", isOn: $isAllDay)

                    if isAllDay {
                        DatePicker("日付", selection: $startTime, displayedComponents: .date)
                    } else {
                        DatePicker("日時", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    }

                    TextField("場所", text: $location)
                }

                Section("準備時間") {
                    Stepper(
                        "準備時間: \(preparationMinutes)分",
                        value: $preparationMinutes,
                        in: 0...120,
                        step: 5
                    )

                    Stepper(
                        "移動時間: \(travelMinutes)分",
                        value: $travelMinutes,
                        in: 0...120,
                        step: 5
                    )

                    HStack {
                        Text("推奨起床時刻")
                        Spacer()
                        Text(suggestedWakeUpTimeString)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }
                }

                Section("優先度") {
                    Picker("優先度", selection: $priority) {
                        ForEach(EventPriority.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("予定を削除")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("予定を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
            .confirmationDialog(
                "この予定を削除しますか？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    private var suggestedWakeUpTimeString: String {
        let totalMinutes = preparationMinutes + travelMinutes
        let wakeUpTime = startTime.addingTimeInterval(TimeInterval(-totalMinutes * 60))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: wakeUpTime)
    }

    private func saveEvent() {
        event.update(
            title: title,
            startTime: startTime,
            location: location.isEmpty ? nil : location,
            preparationMinutes: preparationMinutes,
            travelMinutes: travelMinutes,
            priority: priority,
            isAllDay: isAllDay
        )
        onSave(event)
        dismiss()
    }
}

// MARK: - Preview

#Preview("イベント一覧") {
    EventListView(viewModel: .preview)
}

#Preview("イベント行") {
    List {
        EventRowView(event: .preview)

        EventRowView(event: CalendarEvent.previewList[1])

        EventRowView(event: CalendarEvent.previewList[2])
    }
}
