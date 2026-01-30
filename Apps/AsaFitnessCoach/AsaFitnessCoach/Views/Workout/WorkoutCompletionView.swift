//
//  WorkoutCompletionView.swift
//  AsaFitnessCoach
//
//  ワークアウト完了画面
//

import SwiftUI

struct WorkoutCompletionView: View {
    // MARK: - Properties

    @Bindable var workoutVM: WorkoutViewModel
    let onDismiss: () -> Void

    @State private var selectedRating: SessionRating?
    @State private var perceivedExertion: Int = 5
    @State private var notes: String = ""
    @State private var showAnimation = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 完了アニメーション
                completionHeader

                // サマリー
                summarySection

                // 評価
                ratingSection

                // RPE（主観的運動強度）
                rpeSection

                // メモ
                notesSection

                // 完了ボタン
                Button {
                    saveAndDismiss()
                } label: {
                    Text("完了")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showAnimation = true
            }
        }
    }

    // MARK: - Sections

    private var completionHeader: some View {
        VStack(spacing: 16) {
            // チェックマークアニメーション
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showAnimation ? 1 : 0.5)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .scaleEffect(showAnimation ? 1 : 0)
            }

            Text("ワークアウト完了！")
                .font(.title)
                .fontWeight(.bold)
                .opacity(showAnimation ? 1 : 0)

            Text("お疲れ様でした")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .opacity(showAnimation ? 1 : 0)
        }
        .animation(.easeOut(duration: 0.5).delay(0.2), value: showAnimation)
    }

    private var summarySection: some View {
        VStack(spacing: 16) {
            Text("サマリー")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                SummaryItem(
                    icon: "clock",
                    value: workoutVM.elapsedTimeString,
                    label: "時間"
                )

                Divider()
                    .frame(height: 50)

                SummaryItem(
                    icon: "number",
                    value: "\(workoutVM.completedSets)",
                    label: "セット"
                )

                Divider()
                    .frame(height: 50)

                SummaryItem(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(workoutVM.totalExercises)",
                    label: "種目"
                )

                Divider()
                    .frame(height: 50)

                SummaryItem(
                    icon: "percent",
                    value: "\(Int(workoutVM.session.completionRate * 100))",
                    label: "完了率"
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var ratingSection: some View {
        VStack(spacing: 12) {
            Text("今日のワークアウトはどうでしたか？")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                ForEach(SessionRating.allCases, id: \.self) { rating in
                    Button {
                        selectedRating = rating
                    } label: {
                        VStack(spacing: 4) {
                            Text(rating.emoji)
                                .font(.title)

                            Text(rating.displayName)
                                .font(.caption2)
                                .foregroundStyle(selectedRating == rating ? .white : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedRating == rating ? Color.accentColor : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var rpeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("運動強度 (RPE)")
                    .font(.headline)

                Spacer()

                Text("\(perceivedExertion)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
            }

            Slider(value: Binding(
                get: { Double(perceivedExertion) },
                set: { perceivedExertion = Int($0) }
            ), in: 1...10, step: 1)
            .tint(.accentColor)

            HStack {
                Text("軽い")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("限界")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ（オプション）")
                .font(.headline)

            TextField("今日の感想やメモを入力...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }

    // MARK: - Methods

    private func saveAndDismiss() {
        if let rating = selectedRating {
            workoutVM.setSessionRating(rating)
        }
        workoutVM.setPerceivedExertion(perceivedExertion)
        if !notes.isEmpty {
            workoutVM.setNotes(notes)
        }
        onDismiss()
    }
}

// MARK: - Summary Item

struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let session = WorkoutSession(planName: "テストプラン")
    let plan = WorkoutPlan(name: "テストプラン")
    let vm = WorkoutViewModel(session: session, plan: plan)

    return WorkoutCompletionView(workoutVM: vm, onDismiss: {})
}
