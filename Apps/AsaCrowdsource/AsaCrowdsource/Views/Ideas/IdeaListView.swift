//
//  IdeaListView.swift
//  AsaCrowdsource
//
//  アイデア一覧画面
//

import SwiftUI
import SwiftData
import AsaUIKit

struct IdeaListView: View {
    // MARK: - Properties

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var familyViewModel: FamilyGroupViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.localDataService) private var localDataService

    @State private var viewModel = IdeaListViewModel()
    @State private var showCreateIdea = false
    @State private var showFilters = false
    @State private var selectedIdea: Idea?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if familyViewModel.hasGroup {
                    ideaListContent
                } else {
                    noGroupPlaceholder
                }
            }
            .navigationTitle("アイデア")
            .toolbar {
                if familyViewModel.hasGroup {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            // フィルターボタン
                            Button {
                                showFilters = true
                            } label: {
                                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .foregroundColor(Color(AsaColors.coffeeBrown))
                            }

                            // 新規作成ボタン
                            Button {
                                showCreateIdea = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Color(AsaColors.coffeeBrown))
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateIdea) {
                CreateIdeaView { idea in
                    viewModel.addIdea(idea)
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(viewModel: viewModel)
            }
            .sheet(item: $selectedIdea) { idea in
                IdeaDetailView(ideaId: idea.id) { updatedIdea in
                    viewModel.updateIdea(updatedIdea)
                } onDelete: {
                    viewModel.applyFilters()
                }
            }
            .refreshable {
                await loadData()
            }
            .task {
                setupViewModel()
                await loadData()
            }
        }
    }

    // MARK: - Computed Properties

    private var hasActiveFilters: Bool {
        viewModel.selectedCategory != nil ||
        viewModel.selectedStatus != nil ||
        !viewModel.searchText.isEmpty
    }

    // MARK: - Subviews

    private var ideaListContent: some View {
        VStack(spacing: 0) {
            // 検索バー
            searchBar

            // アクティブフィルター表示
            if hasActiveFilters {
                activeFiltersBar
            }

            // アイデアリスト
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredIdeas.isEmpty {
                emptyStateView
            } else {
                ideaList
            }
        }
        .background(Color(AsaColors.softCream).opacity(0.3))
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(AsaColors.mutedSage))

            TextField("アイデアを検索...", text: Binding(
                get: { viewModel.searchText },
                set: { newValue in
                    viewModel.searchText = newValue
                    viewModel.applyFilters()
                }
            ))
            .textFieldStyle(.plain)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.applyFilters()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = viewModel.selectedCategory {
                    FilterChip(
                        text: category.displayNameWithEmoji,
                        onRemove: { viewModel.clearCategoryFilter() }
                    )
                }

                if let status = viewModel.selectedStatus {
                    FilterChip(
                        text: status.displayNameWithEmoji,
                        onRemove: { viewModel.clearStatusFilter() }
                    )
                }

                if hasActiveFilters {
                    Button("すべてクリア") {
                        viewModel.clearAllFilters()
                    }
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.coffeeBrown))
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
            Text("読み込み中...")
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.mutedSage))
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "lightbulb")
                .font(.system(size: 60))
                .foregroundColor(Color(AsaColors.mutedSage).opacity(0.3))

            if hasActiveFilters {
                Text("条件に一致するアイデアがありません")
                    .font(.headline)
                    .foregroundColor(Color(AsaColors.darkSlate))

                Button("フィルターをクリア") {
                    viewModel.clearAllFilters()
                }
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.coffeeBrown))
            } else {
                Text("アイデアがまだありません")
                    .font(.headline)
                    .foregroundColor(Color(AsaColors.darkSlate))

                Text("新しいアイデアを投稿してみましょう")
                    .font(.subheadline)
                    .foregroundColor(Color(AsaColors.mutedSage))

                Button {
                    showCreateIdea = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("アイデアを投稿")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(AsaColors.coffeeBrown))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    private var ideaList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredIdeas) { idea in
                    IdeaCardView(idea: idea)
                        .onTapGesture {
                            selectedIdea = idea
                        }
                }
            }
            .padding()
        }
    }

    private var noGroupPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(AsaColors.mutedSage).opacity(0.3))

            Text("グループに参加してください")
                .font(.headline)
                .foregroundColor(Color(AsaColors.darkSlate))

            Text("アイデアを共有するには、\nまずグループに参加する必要があります")
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.mutedSage))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Private Methods

    private func setupViewModel() {
        // Environment経由で配布された共有のLocalDataServiceを利用（毎回new禁止）
        guard let dataService = localDataService else { return }
        viewModel.setDataService(dataService)

        if let group = familyViewModel.currentGroup {
            viewModel.setGroupId(group.id.uuidString)
        }
    }

    private func loadData() async {
        if let group = familyViewModel.currentGroup {
            viewModel.setGroupId(group.id.uuidString)
            await viewModel.loadIdeas()
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(Color(AsaColors.darkSlate))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(AsaColors.coffeeBrown).opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Bindable var viewModel: IdeaListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // カテゴリ
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: Binding(
                        get: { viewModel.selectedCategory },
                        set: { newValue in
                            viewModel.selectedCategory = newValue
                            viewModel.applyFilters()
                        }
                    )) {
                        Text("すべて").tag(nil as IdeaCategory?)
                        ForEach(IdeaCategory.allCases) { category in
                            Text(category.displayNameWithEmoji).tag(category as IdeaCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // ステータス
                Section("ステータス") {
                    Picker("ステータス", selection: Binding(
                        get: { viewModel.selectedStatus },
                        set: { newValue in
                            viewModel.selectedStatus = newValue
                            viewModel.applyFilters()
                        }
                    )) {
                        Text("すべて").tag(nil as IdeaStatus?)
                        ForEach(IdeaStatus.allCases) { status in
                            Text(status.displayNameWithEmoji).tag(status as IdeaStatus?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // ソート
                Section("並び順") {
                    Picker("並び順", selection: Binding(
                        get: { viewModel.sortOrder },
                        set: { newValue in
                            viewModel.sortOrder = newValue
                            viewModel.applyFilters()
                        }
                    )) {
                        ForEach(IdeaSortOrder.allCases) { order in
                            Text(order.displayName).tag(order)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // リセット
                Section {
                    Button("フィルターをリセット") {
                        viewModel.clearAllFilters()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    IdeaListView()
        .environmentObject(AuthViewModel())
        .environmentObject(FamilyGroupViewModel())
}
