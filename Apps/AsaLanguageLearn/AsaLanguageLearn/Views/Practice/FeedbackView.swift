//
//  FeedbackView.swift
//  AsaLanguageLearn
//
//  発音評価結果表示画面
//

import SwiftUI

struct FeedbackView: View {
    let result: PronunciationResult
    let item: LearningItem?
    let onNext: () -> Void
    let onRetry: () -> Void

    @State private var showDetails = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // スコア表示
                AccuracyIndicator(result: result)

                // 比較セクション
                comparisonSection

                // 単語マッチ詳細
                if !result.wordMatches.isEmpty {
                    WordMatchList(wordMatches: result.wordMatches)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // 例文セクション
                if let exampleSentence = item?.exampleSentence {
                    exampleSection(
                        sentence: exampleSentence,
                        translation: item?.exampleTranslation
                    )
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            actionButtons
        }
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(spacing: 16) {
            // ターゲットテキスト
            VStack(alignment: .leading, spacing: 4) {
                Label("お手本", systemImage: "speaker.wave.2.fill")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                Text(result.normalizedTarget)
                    .font(.title3.bold())
                    .foregroundColor(Color("AsaDarkSlate"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 認識テキスト
            VStack(alignment: .leading, spacing: 4) {
                Label("あなたの発音", systemImage: "mic.fill")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                Text(result.normalizedRecognized.isEmpty ? "（認識されませんでした）" : result.normalizedRecognized)
                    .font(.title3)
                    .foregroundColor(
                        result.normalizedRecognized.isEmpty
                            ? .secondary
                            : (result.countsAsCorrect ? .green : .orange)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Example Section

    private func exampleSection(sentence: String, translation: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("例文", systemImage: "text.bubble")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            Text(sentence)
                .font(.subheadline)
                .foregroundColor(Color("AsaDarkSlate"))

            if let translation = translation {
                Text(translation)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color("AsaSoftCream").opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // やり直しボタン
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("やり直す")
                }
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("AsaCoffeeBrown"), lineWidth: 2)
                )
            }

            // 次へボタン
            Button(action: onNext) {
                HStack {
                    Text("次へ")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("AsaCoffeeBrown"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            Color("AsaSoftCream")
                .opacity(0.95)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Preview

#Preview {
    let sampleResult = PronunciationResult(
        score: 0.75,
        accuracy: .good,
        normalizedRecognized: "good morning",
        normalizedTarget: "good morning",
        wordMatches: [
            WordMatch(targetWord: "good", recognizedWord: "good", isMatch: true),
            WordMatch(targetWord: "morning", recognizedWord: "morning", isMatch: true),
        ]
    )

    FeedbackView(
        result: sampleResult,
        item: .sampleGoodMorning,
        onNext: {},
        onRetry: {}
    )
}
