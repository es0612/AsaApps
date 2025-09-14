import SwiftUI
import AsaUIKit

struct HabitDetailView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    habitHeaderSection

                    // 統計カード
                    statisticsSection

                    // 最近の記録
                    recentRecordsSection

                    // アクションボタン
                    actionButtonsSection
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("習慣を削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    Task {
                        await viewModel.deleteHabit(habit)
                        dismiss()
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この習慣とすべての記録が削除されます。この操作は取り消せません。")
            }
        }
    }

    // MARK: - Subviews

    private var habitHeaderSection: some View {
        AsaCard {
            VStack(spacing: 16) {
                // アイコン
                Image(systemName: habit.icon)
                    .font(.system(size: 50))
                    .foregroundColor(Color(habit.color))
                    .frame(width: 80, height: 80)
                    .background(Color(habit.color).opacity(0.1))
                    .cornerRadius(20)

                // 習慣名と説明
                VStack(spacing: 8) {
                    Text(habit.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AsaColors.darkSlate)

                    if !habit.habitDescription.isEmpty {
                        Text(habit.habitDescription)
                            .font(.subheadline)
                            .foregroundColor(AsaColors.mutedSage)
                            .multilineTextAlignment(.center)
                    }
                }

                // メタデータ
                HStack(spacing: 20) {
                    Label(habit.category.rawValue, systemImage: habit.category.icon)
                        .font(.caption)
                        .foregroundColor(AsaColors.mocha)

                    Text(habit.targetFrequency.rawValue)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    if habit.reminderTime != nil {
                        Label("リマインダー", systemImage: "bell.fill")
                            .font(.caption)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }

                // ステータス
                if !habit.isActive {
                    Text("現在無効")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AsaColors.mutedSage.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    private var statisticsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatisticCard(
                    title: "現在のストリーク",
                    value: "\(habit.currentStreak)",
                    unit: "日",
                    icon: "flame.fill",
                    iconColor: .orange
                )

                StatisticCard(
                    title: "最長ストリーク",
                    value: "\(habit.longestStreak)",
                    unit: "日",
                    icon: "trophy.fill",
                    iconColor: .yellow
                )
            }

            HStack(spacing: 12) {
                StatisticCard(
                    title: "総完了回数",
                    value: "\(habit.totalCompletions)",
                    unit: "回",
                    icon: "checkmark.circle.fill",
                    iconColor: AsaColors.coffeeBrown
                )

                StatisticCard(
                    title: "達成率",
                    value: String(format: "%.1f", habit.completionRate),
                    unit: "%",
                    icon: "chart.pie.fill",
                    iconColor: AsaColors.mocha
                )
            }
        }
    }

    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近の記録")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
                .padding(.horizontal, 4)

            if habit.records.isEmpty {
                AsaCard {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.largeTitle)
                            .foregroundColor(AsaColors.mutedSage)

                        Text("まだ記録がありません")
                            .font(.subheadline)
                            .foregroundColor(AsaColors.darkSlate)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(habit.records.sorted(by: { $0.completedAt > $1.completedAt }).prefix(5)) { record in
                    RecordRow(record: record)
                }
            }
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            AsaButton(
                title: habit.isActive ? "習慣を無効にする" : "習慣を有効にする",
                action: {
                    Task {
                        await viewModel.toggleHabitActive(habit)
                    }
                },
                color: habit.isActive ? AsaColors.mutedSage : AsaColors.coffeeBrown
            )

            Button {
                showingDeleteAlert = true
            } label: {
                Text("習慣を削除")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatisticCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let iconColor: Color

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(iconColor)

                    Text(title)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AsaColors.darkSlate)

                    Text(unit)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                        .padding(.bottom, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RecordRow: View {
    let record: HabitRecord

    var body: some View {
        AsaCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)

                    if !record.note.isEmpty {
                        Text(record.note)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let mood = record.mood {
                    Text(mood.emoji)
                        .font(.title2)
                }

                if let duration = record.formattedDuration {
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(AsaColors.mocha)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AsaColors.softCream)
                        .cornerRadius(6)
                }
            }
            .padding()
        }
    }
}