//
//  MicButtonView.swift
//  AsaLanguageLearn
//
//  マイクボタン（録音開始/停止）
//

import AsaUIKit
import SwiftUI

struct MicButtonView: View {
    let isRecording: Bool
    let audioLevel: Float
    let onTap: () -> Void

    @State private var pulseAnimation = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 背景のパルスアニメーション
                if isRecording {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(AsaColors.coffeeBrown.opacity(0.3), lineWidth: 2)
                            .scaleEffect(pulseAnimation ? 1.5 + CGFloat(index) * 0.3 : 1.0)
                            .opacity(pulseAnimation ? 0 : 0.5)
                            .animation(
                                .easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.3),
                                value: pulseAnimation
                            )
                    }
                }

                // 音声レベルのリング
                Circle()
                    .stroke(
                        isRecording ? AsaColors.coffeeBrown : Color.gray.opacity(0.3),
                        lineWidth: 4
                    )
                    .scaleEffect(isRecording ? 1.0 + CGFloat(audioLevel) * 0.2 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: audioLevel)

                // メインの円
                Circle()
                    .fill(isRecording ? AsaColors.coffeeBrown : AsaColors.darkSlate)
                    .shadow(
                        color: isRecording ? AsaColors.coffeeBrown.opacity(0.5) : .clear,
                        radius: 10
                    )

                // マイクアイコン
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
        }
        .buttonStyle(.plain)
        .onAppear {
            if isRecording {
                pulseAnimation = true
            }
        }
        .onChange(of: isRecording) { _, newValue in
            pulseAnimation = newValue
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        MicButtonView(
            isRecording: false,
            audioLevel: 0,
            onTap: {}
        )

        MicButtonView(
            isRecording: true,
            audioLevel: 0.5,
            onTap: {}
        )
    }
    .padding()
}
