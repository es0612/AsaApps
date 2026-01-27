//
//  TypingIndicator.swift
//  AsaLiveChat
//
//  入力中インジケータコンポーネント
//

import SwiftUI
import AsaUIKit

/// 入力中を示すアニメーションインジケータ
///
/// 3つのドットがアニメーションで点滅します。
struct TypingIndicator: View {
    let text: String?

    @State private var animationPhase = 0

    private let dotCount = 3
    private let animationDuration: Double = 0.6

    init(text: String? = nil) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // ドットアニメーション
            HStack(spacing: 4) {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(AsaColors.mutedSage)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .opacity(animationPhase == index ? 1.0 : 0.5)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AsaColors.softCream.opacity(0.5))
            .clipShape(Capsule())

            // テキスト（オプション）
            if let text = text {
                Text(text)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: animationDuration / Double(dotCount), repeats: true) { _ in
            withAnimation(.easeInOut(duration: animationDuration / Double(dotCount))) {
                animationPhase = (animationPhase + 1) % dotCount
            }
        }
    }
}

// MARK: - Compact Typing Indicator

/// コンパクトな入力中インジケータ（インライン表示用）
struct CompactTypingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AsaColors.mutedSage)
                    .frame(width: 6, height: 6)
                    .offset(y: isAnimating ? -4 : 0)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever()
                        .delay(Double(index) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview("TypingIndicator") {
    VStack(spacing: 20) {
        TypingIndicator()

        TypingIndicator(text: "パパが入力中...")

        TypingIndicator(text: "ママとパパが入力中...")

        Divider()

        HStack {
            Text("コンパクト:")
            CompactTypingIndicator()
        }
    }
    .padding()
}
