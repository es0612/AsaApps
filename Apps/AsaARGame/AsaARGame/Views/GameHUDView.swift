import SwiftUI
import AsaUIKit

// MARK: - GameHUDView
/// ゲーム中のヘッドアップディスプレイ（スコア、タイマー、コンボ表示）
struct GameHUDView: View {
    let score: Int
    let remainingTime: TimeInterval
    let comboCount: Int
    let highScore: Int
    let onPause: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 上部HUD
            HStack(alignment: .top) {
                // スコア表示
                scoreView
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 一時停止ボタン
                pauseButton

                // タイマー表示
                timerView
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // コンボ表示（コンボ中のみ）
            if comboCount >= 2 {
                comboView
                    .transition(.scale.combined(with: .opacity))
                    .padding(.top, 8)
            }

            Spacer()
        }
        .animation(.easeOut(duration: 0.2), value: comboCount)
    }

    // MARK: - Subviews

    private var scoreView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 現在スコア
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(score)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // ハイスコア
            Text("ハイスコア: \(highScore)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var timerView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .foregroundColor(remainingTime <= 10 ? .red : .white)
                Text(timeString)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(remainingTime <= 10 ? .red : .white)
            }

            if remainingTime <= 10 {
                Text("急いで！")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: remainingTime <= 10)
    }

    private var pauseButton: some View {
        Button(action: onPause) {
            Image(systemName: "pause.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var comboView: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            Text("\(comboCount) COMBO!")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("+\(min(comboCount * 5, 25))")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.8),
            in: Capsule()
        )
    }

    // MARK: - Computed Properties

    private var timeString: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        GameHUDView(
            score: 1250,
            remainingTime: 45,
            comboCount: 5,
            highScore: 2000,
            onPause: {}
        )
    }
}
