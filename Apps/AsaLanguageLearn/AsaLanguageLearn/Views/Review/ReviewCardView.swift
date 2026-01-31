//
//  ReviewCardView.swift
//  AsaLanguageLearn
//
//  復習カード表示と練習画面
//

import SwiftUI
import SwiftData

/// 復習練習画面
struct ReviewPracticeView: View {
    @Bindable var viewModel: ReviewViewModel
    let speechRecognitionService: SpeechRecognitionServiceProtocol
    let textToSpeechService: TextToSpeechServiceProtocol
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @State private var practiceViewModel: PracticeViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AsaSoftCream").opacity(0.3)
                    .ignoresSafeArea()

                if let practiceVM = practiceViewModel {
                    ReviewCardContent(
                        viewModel: practiceVM,
                        reviewViewModel: viewModel,
                        onComplete: {
                            dismiss()
                        }
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("復習")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("\(viewModel.currentIndex + 1) / \(viewModel.totalItems)")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            practiceViewModel = PracticeViewModel(
                speechRecognitionService: speechRecognitionService,
                textToSpeechService: textToSpeechService,
                modelContext: modelContext
            )
            practiceViewModel?.startReview(with: viewModel.itemsToReview)
        }
    }
}

/// 復習カードコンテンツ
struct ReviewCardContent: View {
    @Bindable var viewModel: PracticeViewModel
    @Bindable var reviewViewModel: ReviewViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 進捗バー
            ProgressView(value: reviewViewModel.progress)
                .tint(Color("AsaCoffeeBrown"))
                .padding(.horizontal)

            // メインコンテンツ
            contentView
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .ready, .listening:
            RecordingView(viewModel: viewModel)

        case .processing:
            processingView

        case .showingResult(let result):
            FeedbackView(
                result: result,
                item: viewModel.currentItem,
                onNext: {
                    // 復習結果を記録
                    if result.countsAsCorrect {
                        reviewViewModel.recordCorrect(pronunciationScore: result.score)
                    } else {
                        reviewViewModel.recordIncorrect(pronunciationScore: result.score)
                    }

                    // 次へ進む
                    if reviewViewModel.isCompleted {
                        onComplete()
                    } else {
                        viewModel.nextItem()
                    }
                },
                onRetry: {
                    viewModel.retryCurrentItem()
                }
            )

        case .completed:
            completedView

        case .error(let message):
            errorView(message: message)
        }
    }

    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("評価中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var completedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("復習完了！")
                .font(.title.bold())

            Button("閉じる") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("AsaCoffeeBrown"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("エラーが発生しました")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("やり直す") {
                viewModel.retryCurrentItem()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("AsaCoffeeBrown"))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LearningItem.self, LearningProgress.self, configurations: config)

    ReviewPracticeView(
        viewModel: ReviewViewModel(modelContext: container.mainContext),
        speechRecognitionService: MockSpeechRecognitionService(),
        textToSpeechService: MockTextToSpeechService(),
        modelContext: container.mainContext
    )
}
