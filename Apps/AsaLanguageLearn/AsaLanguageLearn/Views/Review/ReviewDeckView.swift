//
//  ReviewDeckView.swift
//  AsaLanguageLearn
//
//  復習デッキ画面
//

import AsaUIKit
import SwiftUI
import SwiftData

struct ReviewDeckView: View {
    @Bindable var viewModel: ReviewViewModel
    let speechRecognitionService: SpeechRecognitionServiceProtocol
    let textToSpeechService: TextToSpeechServiceProtocol

    @Environment(\.modelContext) private var modelContext
    @State private var showingPractice = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.itemsToReview.isEmpty {
                emptyStateView
            } else if viewModel.isCompleted {
                completedView
            } else {
                reviewContent
            }
        }
        .navigationTitle("復習")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadItemsForReview()
        }
        .fullScreenCover(isPresented: $showingPractice) {
            if !viewModel.itemsToReview.isEmpty {
                ReviewPracticeView(
                    viewModel: viewModel,
                    speechRecognitionService: speechRecognitionService,
                    textToSpeechService: textToSpeechService,
                    modelContext: modelContext
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("復習アイテムを読み込み中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("復習完了！")
                .font(.title2.bold())
                .foregroundColor(AsaColors.darkSlate)

            Text("今日復習するアイテムはありません。\n新しいレッスンを始めましょう！")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AsaColors.softCream.opacity(0.3))
    }

    // MARK: - Review Content

    private var reviewContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 統計カード
                statsCard

                // 習熟レベル分布
                masteryLevelSection

                // 開始ボタン
                startButton
            }
            .padding()
        }
        .background(AsaColors.softCream.opacity(0.3))
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.totalItems)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(AsaColors.coffeeBrown)

                    Text("復習待ちのアイテム")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AsaColors.coffeeBrown.opacity(0.3))
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Mastery Level Section

    private var masteryLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("習熟レベル別")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                    let count = viewModel.masteryLevelCounts[level] ?? 0
                    if count > 0 {
                        MasteryLevelBadge(level: level, count: count)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            showingPractice = true
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("復習を始める")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AsaColors.coffeeBrown)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 30) {
            Spacer()

            // 完了アイコン
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }

            Text("復習完了！")
                .font(.title.bold())

            // 統計
            let summary = viewModel.sessionSummary
            VStack(spacing: 16) {
                HStack(spacing: 40) {
                    StatItem(title: "正解", value: "\(summary.correctCount)", color: .green)
                    StatItem(title: "不正解", value: "\(summary.incorrectCount)", color: .red)
                }

                Text("正解率: \(summary.correctRateText)")
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            Button {
                Task {
                    await viewModel.loadItemsForReview()
                }
            } label: {
                Text("閉じる")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AsaColors.coffeeBrown)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.3))
    }
}

// MARK: - Mastery Level Badge

struct MasteryLevelBadge: View {
    let level: MasteryLevel
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.title3)
                .foregroundColor(level.color)

            Text("\(count)")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            Text(level.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(level.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LearningItem.self, LearningProgress.self, configurations: config)

    NavigationStack {
        ReviewDeckView(
            viewModel: ReviewViewModel(modelContext: container.mainContext),
            speechRecognitionService: MockSpeechRecognitionService(),
            textToSpeechService: MockTextToSpeechService()
        )
    }
}
