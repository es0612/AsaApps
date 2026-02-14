import SwiftUI
import SwiftData
import AsaLifeLogKit

// MARK: - TimelineView

/// タイムライン表示ビュー
struct TimelineView: View {
    @Bindable var viewModel: TimelineViewModel
    @Bindable var editorViewModel: EntryEditorViewModel
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TimelineFilterBar(
                    selectedDate: $viewModel.selectedDate,
                    selectedSource: $viewModel.selectedSource,
                    onDateChanged: {
                        Task { await viewModel.loadEntries() }
                    }
                )

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredEntries.isEmpty {
                    EmptyStateView(
                        icon: "clock.badge.questionmark",
                        title: "エントリーがありません",
                        message: "今日のライフログを記録しましょう",
                        actionTitle: "記録する"
                    ) {
                        showEditor = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            TimelineDateHeader(date: viewModel.selectedDate)

                            ForEach(viewModel.filteredEntries, id: \.id) { entry in
                                TimelineEntryRow(entry: entry) {
                                    Task { await viewModel.toggleFavorite(entry) }
                                } onDelete: {
                                    Task { await viewModel.deleteEntry(entry) }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("タイムライン")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editorViewModel.resetForm()
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                Task { await viewModel.loadEntries() }
            } content: {
                EntryEditorSheet(viewModel: editorViewModel, isPresented: $showEditor)
            }
            .task {
                await viewModel.loadEntries()
            }
            .refreshable {
                await viewModel.loadEntries()
            }
        }
    }
}
