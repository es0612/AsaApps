//
//  DiaryListView.swift
//  AsaVRDiary
//
//  日記一覧画面
//

import SwiftUI

/// 日記一覧画面
struct DiaryListView: View {
    @Bindable var viewModel: DiaryViewModel
    @State private var showingAddSheet = false
    @State private var showingFilterSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    diaryList
                }
            }
            .navigationTitle("日記")
            .searchable(text: $viewModel.searchText, prompt: "タイトルや内容で検索")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    addButton
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddDiaryView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadEntries()
            }
        }
    }

    // MARK: - Subviews

    /// 日記リスト
    private var diaryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // フィルター表示
                if viewModel.selectedCategory != nil ||
                    viewModel.selectedMood != nil ||
                    viewModel.showFavoritesOnly {
                    activeFiltersView
                }

                // 日記カード
                ForEach(viewModel.filteredEntries) { entry in
                    NavigationLink {
                        DiaryDetailView(entry: entry, viewModel: viewModel)
                    } label: {
                        DiaryCard(
                            entry: entry,
                            onFavoriteToggle: {
                                viewModel.toggleFavorite(entry)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    /// 空状態ビュー
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("日記がありません")
                .font(.title2)
                .fontWeight(.medium)

            if viewModel.entries.isEmpty {
                Text("最初の日記を書いてみましょう")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("日記を追加") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)

                Button("サンプルデータを作成") {
                    viewModel.createSampleData()
                }
                .buttonStyle(.bordered)
            } else {
                Text("フィルター条件に一致する日記がありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("フィルターをリセット") {
                    viewModel.resetFilters()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    /// アクティブなフィルター表示
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = viewModel.selectedCategory {
                    FilterChip(
                        label: category.displayName,
                        icon: category.icon,
                        color: category.color,
                        onRemove: { viewModel.selectedCategory = nil }
                    )
                }

                if let mood = viewModel.selectedMood {
                    FilterChip(
                        label: mood.displayName,
                        icon: nil,
                        emoji: mood.emoji,
                        color: mood.color,
                        onRemove: { viewModel.selectedMood = nil }
                    )
                }

                if viewModel.showFavoritesOnly {
                    FilterChip(
                        label: "お気に入り",
                        icon: "star.fill",
                        color: .yellow,
                        onRemove: { viewModel.showFavoritesOnly = false }
                    )
                }

                Button("すべてクリア") {
                    viewModel.resetFilters()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    /// フィルターボタン
    private var filterButton: some View {
        Button {
            showingFilterSheet = true
        } label: {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    /// 追加ボタン
    private var addButton: some View {
        Button {
            showingAddSheet = true
        } label: {
            Image(systemName: "plus")
        }
    }

    /// アクティブなフィルターがあるか
    private var hasActiveFilters: Bool {
        viewModel.selectedCategory != nil ||
        viewModel.selectedMood != nil ||
        viewModel.showFavoritesOnly
    }
}

/// フィルターチップ
struct FilterChip: View {
    let label: String
    var icon: String?
    var emoji: String?
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            if let emoji = emoji {
                Text(emoji)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
            }

            Text(label)
                .font(.caption)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

/// フィルターシート
struct FilterSheet: View {
    @Bindable var viewModel: DiaryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $viewModel.selectedCategory) {
                        Text("すべて").tag(nil as DiaryCategory?)
                        ForEach(DiaryCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category as DiaryCategory?)
                        }
                    }
                }

                Section("気分") {
                    Picker("気分", selection: $viewModel.selectedMood) {
                        Text("すべて").tag(nil as DiaryMood?)
                        ForEach(DiaryMood.allCases, id: \.self) { mood in
                            Text("\(mood.emoji) \(mood.displayName)")
                                .tag(mood as DiaryMood?)
                        }
                    }
                }

                Section {
                    Toggle("お気に入りのみ", isOn: $viewModel.showFavoritesOnly)
                }

                Section {
                    Button("フィルターをリセット") {
                        viewModel.resetFilters()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    DiaryListView(viewModel: DiaryViewModel())
}
