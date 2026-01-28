import SwiftUI
import SwiftData

struct StudyItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyItem.aiPriorityScore, order: .reverse) private var studyItems: [StudyItem]

    @State private var showingAddItem = false
    @State private var searchText = ""
    @State private var selectedCategory: StudyCategory?
    @State private var showCompleted = false

    private var filteredItems: [StudyItem] {
        var items = studyItems.filter { !$0.isArchived }

        if !showCompleted {
            items = items.filter { !$0.isCompleted }
        }

        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            items = items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        return items
    }

    var body: some View {
        NavigationStack {
            List {
                // カテゴリフィルター
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryFilterChip(
                                title: "すべて",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }

                            ForEach(StudyCategory.allCases, id: \.self) { category in
                                CategoryFilterChip(
                                    title: category.displayName,
                                    emoji: category.emoji,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // 学習項目リスト
                if filteredItems.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "学習項目がありません",
                            systemImage: "book.closed",
                            description: Text("「+」ボタンから学習項目を追加しましょう")
                        )
                    }
                } else {
                    Section {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                StudyItemDetailView(item: item)
                            } label: {
                                StudyItemRow(item: item)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    } header: {
                        HStack {
                            Text("\(filteredItems.count)件")
                            Spacer()
                            Toggle("完了も表示", isOn: $showCompleted)
                                .toggleStyle(.button)
                                .buttonStyle(.borderless)
                                .font(.caption)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "検索")
            .navigationTitle("学習項目")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddStudyItemView()
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            modelContext.delete(item)
        }
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    var emoji: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let emoji = emoji {
                    Text(emoji)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color("AsaCoffeeBrown") : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Study Item Row

struct StudyItemRow: View {
    let item: StudyItem

    var body: some View {
        HStack(spacing: 12) {
            // カテゴリアイコン
            Text(item.category.emoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .clipShape(Circle())

            // 情報
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)

                    if item.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 8) {
                    // 難易度
                    Label(item.difficulty.displayName, systemImage: item.difficulty.icon)
                        .font(.caption)
                        .foregroundStyle(item.difficulty.color)

                    // 習熟度
                    Text(item.masteryLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // 期限
                    if let days = item.daysUntilTarget {
                        Text(days < 0 ? "期限切れ" : "あと\(days)日")
                            .font(.caption)
                            .foregroundStyle(days < 0 ? .red : .secondary)
                    }
                }

                // 習熟度プログレス
                ProgressView(value: item.masteryLevel)
                    .tint(masteryColor)
            }

            Spacer()

            // 優先度スコア
            VStack {
                PriorityBadge(score: item.aiPriorityScore)
                if item.needsReview {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var masteryColor: Color {
        switch item.masteryLevel {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .yellow
        default: return .orange
        }
    }
}

#Preview {
    StudyItemListView()
        .modelContainer(for: [
            StudyItem.self,
            StudySession.self,
            StudyPlan.self,
            LearningAnalytics.self,
            UserLearningProfile.self
        ], inMemory: true)
}
