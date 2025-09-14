import SwiftUI
import AsaUIKit

struct DashboardView: View {
    let viewModel: HabitViewModel
    @State private var showingAddHabit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日の進捗カード
                    todayProgressCard

                    // 今日の習慣リスト
                    todayHabitsSection

                    // クイック統計
                    quickStatsSection
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationTitle("今日の習慣")
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
            .refreshable {
                await viewModel.loadHabits()
            }
        }
    }

    // MARK: - Subviews

    private var todayProgressCard: some View {
        AsaCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日の進捗")
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)

                        Text("\(viewModel.totalCompletedToday) / \(viewModel.todayHabits.count) 完了")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }

                    Spacer()

                    // 円形プログレス
                    ZStack {
                        Circle()
                            .stroke(AsaColors.softCream, lineWidth: 10)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: viewModel.todayProgress)
                            .stroke(AsaColors.coffeeBrown, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: viewModel.todayProgress)

                        Text("\(Int(viewModel.todayProgress * 100))%")
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)
                    }
                }

                // 励ましメッセージ
                if viewModel.todayProgress == 1.0 {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("素晴らしい！今日の習慣を全て完了しました！")
                            .font(.caption)
                            .foregroundColor(AsaColors.mocha)
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(AsaColors.softCream.opacity(0.5))
                    .cornerRadius(8)
                } else if viewModel.todayProgress > 0.5 {
                    Text("順調です！あと少しで今日の目標達成です")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .padding()
        }
    }

    private var todayHabitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の習慣")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
                .padding(.horizontal, 4)

            if viewModel.todayHabits.isEmpty {
                AsaCard {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(AsaColors.mutedSage)

                        Text("今日の習慣はありません")
                            .font(.subheadline)
                            .foregroundColor(AsaColors.darkSlate)

                        AsaButton(title: "習慣を追加") {
                            showingAddHabit = true
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(viewModel.todayHabits) { habit in
                    TodayHabitRow(habit: habit, viewModel: viewModel)
                }
            }
        }
    }

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("統計")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                StatCard(
                    title: "総習慣数",
                    value: "\(viewModel.totalActiveHabits)",
                    icon: "list.bullet",
                    color: AsaColors.mocha
                )

                StatCard(
                    title: "今週の達成率",
                    value: "85%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: AsaColors.coffeeBrown
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct TodayHabitRow: View {
    let habit: Habit
    let viewModel: HabitViewModel
    @State private var isCompleted: Bool = false
    @State private var isAnimating = false

    var body: some View {
        AsaCard {
            HStack(spacing: 16) {
                // アイコン
                Image(systemName: habit.icon)
                    .font(.title2)
                    .foregroundColor(Color(habit.color))
                    .frame(width: 40, height: 40)
                    .background(Color(habit.color).opacity(0.1))
                    .cornerRadius(10)

                // 習慣名とストリーク
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                        .strikethrough(isCompleted, color: AsaColors.mutedSage)

                    HStack(spacing: 8) {
                        if habit.currentStreak > 0 {
                            Label("\(habit.currentStreak)日連続", systemImage: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        Text(habit.category.rawValue)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AsaColors.softCream)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                // チェックボックス
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isAnimating = true
                        isCompleted.toggle()
                    }

                    Task {
                        if isCompleted {
                            await viewModel.recordCompletion(for: habit)
                        } else {
                            await viewModel.removeCompletion(for: habit)
                        }
                        isAnimating = false
                    }
                } label: {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(isCompleted ? AsaColors.coffeeBrown : AsaColors.mutedSage)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
        .onAppear {
            isCompleted = habit.isCompletedToday
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)

                    Text(title)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.darkSlate)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}