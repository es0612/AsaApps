import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// イベントカレンダー画面
struct EventCalendarView: View {
    @Bindable var viewModel: EventCalendarViewModel
    @State private var showCreateEvent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Date Picker
                DatePicker(
                    "日付選択",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(AsaColors.coffeeBrown)
                .padding(.horizontal)

                Divider()

                // MARK: - Event List
                if viewModel.eventsForSelectedDate.isEmpty {
                    Spacer()
                    EmptyStateView(
                        iconName: "calendar.badge.exclamationmark",
                        title: "イベントなし",
                        message: "この日にイベントは予定されていません",
                        actionTitle: "イベントを作成",
                        action: { showCreateEvent = true }
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.eventsForSelectedDate) { event in
                            NavigationLink {
                                EventDetailView(
                                    event: event,
                                    viewModel: viewModel
                                )
                            } label: {
                                EventListRow(event: event)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("イベント")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateEvent = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventSheet(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadEvents()
            }
        }
    }
}

/// イベントリスト行コンポーネント
struct EventListRow: View {
    let event: CommunityEvent

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(event.startDate.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AsaColors.coffeeBrown)
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack {
                    Label(event.location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("\(event.attendeeCount)人参加", systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
