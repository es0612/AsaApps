//
//  AnswerInputView.swift
//  AsaMultiplayerGame
//
//  回答入力コンポーネント
//

import SwiftUI
import AsaUIKit

/// 回答入力ビュー
///
/// 当てる側のプレイヤーが回答を入力するためのコンポーネントです。
struct AnswerInputView: View {
    // MARK: - Properties

    @Binding var answer: String
    var onSubmit: () -> Void
    var isEnabled: Bool = true

    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // 入力フィールド
            HStack(spacing: 12) {
                // テキストフィールド
                TextField("答えを入力...", text: $answer)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .onSubmit {
                        if !answer.isEmpty && isEnabled {
                            onSubmit()
                        }
                    }
                    .disabled(!isEnabled)

                // 送信ボタン
                Button(action: onSubmit) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(isEnabled && !answer.isEmpty ? AsaColors.coffeeBrown : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isEnabled || answer.isEmpty)
            }

            // ヒント
            Text("お題を当ててください！")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Word Display View

/// お題表示ビュー（描く側用）
struct WordDisplayView: View {
    let word: String

    var body: some View {
        VStack(spacing: 8) {
            Text("お題")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)

            Text(word)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.darkSlate)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AsaColors.softCream)
                .cornerRadius(12)

            Text("このお題を絵で表現してください")
                .font(.caption2)
                .foregroundColor(AsaColors.mutedSage)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Preview

#Preview("Answer Input") {
    struct PreviewWrapper: View {
        @State private var answer = ""

        var body: some View {
            AnswerInputView(
                answer: $answer,
                onSubmit: { print("Submit: \(answer)") }
            )
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("Word Display") {
    WordDisplayView(word: "りんご")
        .padding()
}
