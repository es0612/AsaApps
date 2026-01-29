//
//  RecognizedTextView.swift
//  AsaVoiceAssistant
//
//  音声認識テキスト表示コンポーネント
//

import SwiftUI
import AsaUIKit

/// 音声認識テキスト表示ビュー
///
/// リアルタイムで認識されるテキストを表示します。
/// 認識中はカーソルアニメーションで入力中であることを示します。
struct RecognizedTextView: View {
    // MARK: - Properties

    let text: String
    let isListening: Bool

    @State private var showCursor = true

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // 状態ラベル
            HStack {
                Circle()
                    .fill(isListening ? Color.red : AsaColors.mutedSage)
                    .frame(width: 8, height: 8)

                Text(isListening ? "認識中..." : "待機中")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }

            // テキスト表示エリア
            ZStack(alignment: .leading) {
                // プレースホルダー
                if text.isEmpty && !isListening {
                    Text("マイクボタンを押して話しかけてください")
                        .font(.body)
                        .foregroundColor(AsaColors.mutedSage.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                // 認識テキスト
                HStack(alignment: .bottom, spacing: 2) {
                    Text(text)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(AsaColors.darkSlate)
                        .multilineTextAlignment(.center)

                    // カーソル
                    if isListening && showCursor {
                        Rectangle()
                            .fill(AsaColors.coffeeBrown)
                            .frame(width: 2, height: 24)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(minHeight: 60)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .onAppear {
            startCursorAnimation()
        }
    }

    // MARK: - Animation

    private func startCursorAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showCursor.toggle()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RecognizedTextView(
            text: "",
            isListening: false
        )

        RecognizedTextView(
            text: "明日までに",
            isListening: true
        )

        RecognizedTextView(
            text: "明日までに報告書を作成する",
            isListening: false
        )
    }
    .padding()
    .background(AsaColors.softCream)
}
