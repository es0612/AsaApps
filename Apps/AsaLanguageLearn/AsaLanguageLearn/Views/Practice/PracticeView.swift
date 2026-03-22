//
//  PracticeView.swift
//  AsaLanguageLearn
//
//  発音練習画面
//

import AsaUIKit
import SwiftUI
import SwiftData

struct PracticeView: View {
    let lesson: Lesson

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PracticeViewModel

    init(
        lesson: Lesson,
        speechRecognitionService: SpeechRecognitionServiceProtocol,
        textToSpeechService: TextToSpeechServiceProtocol,
        modelContext: ModelContext
    ) {
        self.lesson = lesson
        self._viewModel = State(initialValue: PracticeViewModel(
            speechRecognitionService: speechRecognitionService,
            textToSpeechService: textToSpeechService,
            modelContext: modelContext
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.softCream.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 進捗バー
                    ProgressView(value: viewModel.progress)
                        .tint(AsaColors.coffeeBrown)
                        .padding(.horizontal)

                    // メインコンテンツ
                    contentView
                }
            }
            .navigationTitle(lesson.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("\(viewModel.completedItems + 1) / \(viewModel.totalItems)")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            viewModel.startPractice(with: lesson)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .ready:
            RecordingView(viewModel: viewModel)

        case .listening:
            RecordingView(viewModel: viewModel)

        case .processing:
            processingView

        case .showingResult(let result):
            FeedbackView(
                result: result,
                item: viewModel.currentItem,
                onNext: { viewModel.nextItem() },
                onRetry: { viewModel.retryCurrentItem() }
            )

        case .completed:
            completedView

        case .error(let message):
            errorView(message: message)
        }
    }

    // MARK: - Processing View

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

            Text("レッスン完了！")
                .font(.title.bold())
                .foregroundColor(AsaColors.darkSlate)

            // 統計
            VStack(spacing: 16) {
                HStack(spacing: 40) {
                    StatItem(title: "正解", value: "\(viewModel.correctCount)", color: .green)
                    StatItem(title: "不正解", value: "\(viewModel.incorrectCount)", color: .red)
                }

                if viewModel.correctCount + viewModel.incorrectCount > 0 {
                    let rate = Double(viewModel.correctCount) / Double(viewModel.correctCount + viewModel.incorrectCount)
                    Text("正解率: \(Int(rate * 100))%")
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            // ボタン
            VStack(spacing: 12) {
                Button {
                    viewModel.resetSession()
                } label: {
                    Text("もう一度練習")
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AsaColors.softCream)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    dismiss()
                } label: {
                    Text("終了")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AsaColors.coffeeBrown)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .padding()
    }

    // MARK: - Error View

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
                .multilineTextAlignment(.center)

            Button("やり直す") {
                viewModel.retryCurrentItem()
            }
            .buttonStyle(.borderedProminent)
            .tint(AsaColors.coffeeBrown)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Course.self, Lesson.self, LearningItem.self, LearningProgress.self, configurations: config)

    PracticeView(
        lesson: .sampleMorningGreetings,
        speechRecognitionService: MockSpeechRecognitionService(),
        textToSpeechService: MockTextToSpeechService(),
        modelContext: container.mainContext
    )
}
