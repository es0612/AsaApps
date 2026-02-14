import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// イベント一覧表示（リスト形式）
struct EventListView: View {
    @Bindable var viewModel: EventCalendarViewModel

    var body: some View {
        List {
            if !viewModel.upcomingEvents.isEmpty {
                Section("今後のイベント") {
                    ForEach(viewModel.upcomingEvents) { event in
                        NavigationLink {
                            EventDetailView(event: event, viewModel: viewModel)
                        } label: {
                            EventListRow(event: event)
                        }
                    }
                }
            }

            if viewModel.showPastEvents {
                let pastEvents = viewModel.events.filter(\.isPast)
                if !pastEvents.isEmpty {
                    Section("過去のイベント") {
                        ForEach(pastEvents) { event in
                            NavigationLink {
                                EventDetailView(event: event, viewModel: viewModel)
                            } label: {
                                EventListRow(event: event)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.events.isEmpty {
                EmptyStateView(
                    iconName: "calendar",
                    title: "イベントなし",
                    message: "まだイベントが登録されていません"
                )
            }
        }
    }
}
