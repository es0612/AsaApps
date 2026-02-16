//
//  StreamingResponseView.swift
//  AsaPapaHub
//
//  テキストが段階的に表示される汎用ストリーミングコンポーネント
//

import SwiftUI

// MARK: - StreamingResponseView

/// AI レスポンスをタイプライター風に表示する汎用コンポーネント
struct StreamingResponseView: View {
    // MARK: - Properties

    let text: String
    let isLoading: Bool

    @State private var displayedText = ""
    @State private var charIndex = 0

    private let coffeeBrown = Color(red: 0.776, green: 0.549, blue: 0.325)
    private let darkSlate = Color(red: 0.184, green: 0.243, blue: 0.275)

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading && displayedText.isEmpty {
                loadingIndicator
            } else {
                Text(displayedText)
                    .font(.body)
                    .foregroundStyle(darkSlate)
                    .animation(.easeInOut(duration: 0.1), value: displayedText)

                if isLoading {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.small)
                        Text("生成中...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onChange(of: text) { _, newValue in
            updateDisplayText(newValue)
        }
        .onAppear {
            if !text.isEmpty {
                updateDisplayText(text)
            }
        }
    }

    // MARK: - Subviews

    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)

            Text("AIが考えています...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Methods

    private func updateDisplayText(_ newText: String) {
        // ストリーミング: 新しいテキストが前のテキストを含む場合、差分だけ追加
        if newText.hasPrefix(displayedText) {
            displayedText = newText
        } else {
            // テキストが完全に変わった場合はリセット
            displayedText = newText
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StreamingResponseView(
            text: "おはようございます！今日も素晴らしい朝を迎えられましたね。",
            isLoading: false
        )

        StreamingResponseView(
            text: "",
            isLoading: true
        )

        StreamingResponseView(
            text: "生成中のテキスト...",
            isLoading: true
        )
    }
    .padding()
}
