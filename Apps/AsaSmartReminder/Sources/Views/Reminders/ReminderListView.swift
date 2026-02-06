import AsaSmartReminderKit
import AsaUIKit
import SwiftUI

// MARK: - リマインダー一覧

struct ReminderListView: View {
    @Bindable var viewModel: SmartReminderViewModel
    let dataService: ReminderDataService

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // フィルタセグメント
                Picker("フィルタ", selection: $viewModel.selectedFilter) {
                    ForEach(SmartReminderViewModel.ReminderFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // リマインダー一覧
                if viewModel.filteredReminders.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "リマインダーがありません",
                        description: "＋ボタンから新しいリマインダーを追加しましょう"
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredReminders) { reminder in
                            ReminderCardView(
                                reminder: reminder,
                                onToggle: { viewModel.toggleCompletion(reminder) }
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            let reminders = viewModel.filteredReminders
                            for index in offsets {
                                viewModel.deleteReminder(reminders[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("リマインダー")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    MonitoringStatusBadge(state: viewModel.monitoringState)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAddReminder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .tint(AsaColors.coffeeBrown)
                }
            }
            .sheet(isPresented: $viewModel.showingAddReminder) {
                AddReminderView(viewModel: viewModel, dataService: dataService)
            }
            .alert("エラー", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
