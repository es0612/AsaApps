//
//  TimerView.swift
//  AsaMultiplayerGame
//
//  タイマー表示コンポーネント
//

import SwiftUI

/// タイマー表示ビュー
///
/// 残り時間を視覚的に表示し、残り時間が少なくなると警告色に変化します。
struct TimerView: View {
    // MARK: - Properties

    /// 残り時間（秒）
    let remainingTime: Int

    /// 総時間（秒）
    let totalTime: Int

    /// 警告を表示する閾値（秒）
    var warningThreshold: Int = 10

    /// 危険を表示する閾値（秒）
    var dangerThreshold: Int = 5

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // タイマーアイコン
            Image(systemName: "timer")
                .font(.title2)
                .foregroundColor(timerColor)

            // 残り時間テキスト
            Text(timeString)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(timerColor)

            // プログレスバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // プログレス
                    RoundedRectangle(cornerRadius: 4)
                        .fill(timerColor)
                        .frame(width: progressWidth(for: geometry.size.width), height: 8)
                        .animation(.linear(duration: 0.5), value: remainingTime)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(12)
    }

    // MARK: - Computed Properties

    private var timeString: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(remainingTime) / Double(totalTime)
    }

    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        max(0, totalWidth * progress)
    }

    private var timerColor: Color {
        if remainingTime <= dangerThreshold {
            return .red
        } else if remainingTime <= warningThreshold {
            return .orange
        } else {
            return Color("AsaCoffeeBrown")
        }
    }

    private var backgroundColor: Color {
        if remainingTime <= dangerThreshold {
            return .red.opacity(0.1)
        } else if remainingTime <= warningThreshold {
            return .orange.opacity(0.1)
        } else {
            return Color("AsaSoftCream")
        }
    }
}

// MARK: - Countdown View

/// カウントダウン表示ビュー
struct CountdownView: View {
    let number: Int

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // カウントダウン数字
            Text("\(number)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(1.0)
                .animation(.easeOut(duration: 0.3), value: number)
        }
    }
}

// MARK: - Preview

#Preview("Timer") {
    VStack(spacing: 20) {
        TimerView(remainingTime: 25, totalTime: 30)
        TimerView(remainingTime: 8, totalTime: 30)
        TimerView(remainingTime: 3, totalTime: 30)
    }
    .padding()
}

#Preview("Countdown") {
    CountdownView(number: 3)
}
