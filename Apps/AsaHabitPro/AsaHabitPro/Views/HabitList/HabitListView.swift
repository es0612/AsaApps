import SwiftUI
import AsaUIKit

struct HabitListView: View {
    let viewModel: HabitViewModel
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // カテゴリフィルター
                    categoryFilterSection

                    // 習慣リスト
                    if viewModel.filteredHabits.isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredHabits) { habit in
                                HabitRowView(habit: habit, viewModel: viewModel)
                                    .onTapGesture {
                                        selectedHabit = habit
                                    }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationTitle("習慣一覧")
            .searchable(text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.searchText = $0 }
            ), prompt: "習慣を検索")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(viewModel: viewModel)
            }
            .sheet(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit, viewModel: viewModel)
            }
        }
    }

    // MARK: - Subviews

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "すべて",
                    isSelected: viewModel.selectedCategory == nil,
                    action: {
                        withAnimation {
                            viewModel.selectedCategory = nil
                        }
                    }
                )

                ForEach(HabitCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category,
                        action: {
                            withAnimation {
                                viewModel.selectedCategory = category
                            }
                        }
                    )
                }
            }
        }
    }

    private var emptyStateView: some View {
        AsaCard {
            VStack(spacing: 20) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 60))
                    .foregroundColor(AsaColors.mutedSage)

                Text("習慣が見つかりません")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                if !viewModel.searchText.isEmpty {
                    Text("検索条件を変更してみてください")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)
                } else {
                    AsaButton(title: "最初の習慣を追加") {
                        showingAddHabit = true
                    }
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Supporting Views

struct HabitRowView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    var body: some View {
        AsaCard {
            HStack(spacing: 16) {
                // アイコン
                Image(systemName: habit.icon)
                    .font(.title2)
                    .foregroundColor(Color(habit.color))
                    .frame(width: 50, height: 50)
                    .background(Color(habit.color).opacity(0.1))
                    .cornerRadius(12)

                // 習慣情報
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Text(habit.habitDescription.isEmpty ? "説明なし" : habit.habitDescription)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        // カテゴリ
                        Label(habit.category.rawValue, systemImage: habit.category.icon)
                            .font(.caption)
                            .foregroundColor(AsaColors.mocha)

                        // 頻度
                        Text(habit.targetFrequency.rawValue)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                Spacer()

                // 統計情報
                VStack(alignment: .trailing, spacing: 4) {
                    if habit.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Text("\(habit.currentStreak)")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    Text("\(habit.totalCompletions)回")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    if !habit.isActive {
                        Text("無効")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AsaColors.mutedSage.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
        }
    }
}

struct CategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AsaColors.coffeeBrown : AsaColors.softCream)
            .foregroundColor(isSelected ? .white : AsaColors.darkSlate)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}