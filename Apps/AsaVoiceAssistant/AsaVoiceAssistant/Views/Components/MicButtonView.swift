//
//  MicButtonView.swift
//  AsaVoiceAssistant
//
//  マイクボタンコンポーネント
//

import SwiftUI
import AsaUIKit

/// マイクボタンビュー
///
/// 音声入力の開始/停止を行うメインボタンです。
/// 録音中は波形アニメーションと赤いパルスで視覚的フィードバックを提供します。
struct MicButtonView: View {
    // MARK: - Properties

    let isListening: Bool
    let audioLevel: Float
    let showWaveform: Bool
    let onTap: () -> Void

    @State private var isPulsing = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景のパルスアニメーション
            if isListening {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.red.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: pulseSize(for: index), height: pulseSize(for: index))
                        .scaleEffect(isPulsing ? 1.5 : 1.0)
                        .opacity(isPulsing ? 0.0 : 1.0)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: isPulsing
                        )
                }
            }

            // 波形表示
            if isListening && showWaveform {
                WaveformCircleView(level: audioLevel)
                    .frame(width: 120, height: 120)
            }

            // メインボタン
            Button(action: onTap) {
                ZStack {
                    // 背景
                    Circle()
                        .fill(isListening ? Color.red : AsaColors.coffeeBrown)
                        .frame(width: 80, height: 80)
                        .shadow(color: (isListening ? Color.red : AsaColors.coffeeBrown).opacity(0.4),
                                radius: 10, x: 0, y: 5)

                    // アイコン
                    Image(systemName: isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(width: 160, height: 160)
        .onChange(of: isListening) { _, newValue in
            isPulsing = newValue
        }
    }

    // MARK: - Helper

    private func pulseSize(for index: Int) -> CGFloat {
        100 + CGFloat(index * 30)
    }
}

/// 波形サークルビュー
struct WaveformCircleView: View {
    let level: Float
    let barCount: Int = 20

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 10

            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    level: level,
                    index: index,
                    totalBars: barCount
                )
                .frame(width: 4, height: barHeight(for: index))
                .position(barPosition(index: index, center: center, radius: radius))
                .rotationEffect(.degrees(Double(index) * (360.0 / Double(barCount))), anchor: .center)
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 15
        let levelMultiplier = CGFloat(level) * 20
        let randomVariation = CGFloat.random(in: 0...5)
        return baseHeight + levelMultiplier + randomVariation
    }

    private func barPosition(index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = (Double(index) * (360.0 / Double(barCount))) * .pi / 180
        let x = center.x + radius * CGFloat(cos(angle))
        let y = center.y + radius * CGFloat(sin(angle))
        return CGPoint(x: x, y: y)
    }
}

/// 個別の波形バー
struct WaveformBar: View {
    let level: Float
    let index: Int
    let totalBars: Int

    @State private var animatedHeight: CGFloat = 15

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.red.opacity(0.7))
            .animation(.easeInOut(duration: 0.1), value: level)
    }
}

/// ボタンのスケールアニメーションスタイル
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        MicButtonView(
            isListening: false,
            audioLevel: 0.0,
            showWaveform: true,
            onTap: {}
        )

        MicButtonView(
            isListening: true,
            audioLevel: 0.5,
            showWaveform: true,
            onTap: {}
        )
    }
    .padding()
}
