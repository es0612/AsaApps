import SwiftUI
import AsaUIKit

// MARK: - ARPlaneGuideView
/// 平面検出ガイド表示
struct ARPlaneGuideView: View {
    let guideMessage: String?
    let isPlaneDetected: Bool
    let gameState: GameState

    @State private var isAnimating = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // 状態アイコン
            statusIcon
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    isPlaneDetected ? nil : .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            // ガイドメッセージ
            if let message = guideMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .onAppear {
            isAnimating = true
        }
    }

    // MARK: - Subviews

    private var statusIcon: some View {
        ZStack {
            // 背景円
            Circle()
                .fill(statusColor.opacity(0.3))
                .frame(width: 60, height: 60)

            // アイコン
            Image(systemName: statusIconName)
                .font(.system(size: 28))
                .foregroundColor(statusColor)
        }
    }

    // MARK: - Computed Properties

    private var statusIconName: String {
        switch gameState {
        case .idle, .waitingForPlane:
            return "viewfinder"
        case .ready:
            return "checkmark.circle.fill"
        case .playing:
            return "target"
        case .paused:
            return "pause.circle.fill"
        case .gameOver:
            return "flag.checkered"
        }
    }

    private var statusColor: Color {
        switch gameState {
        case .idle, .waitingForPlane:
            return .blue
        case .ready:
            return .green
        case .playing:
            return .orange
        case .paused:
            return .yellow
        case .gameOver:
            return .purple
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            ARPlaneGuideView(
                guideMessage: "床やテーブルにカメラを向けてください",
                isPlaneDetected: false,
                gameState: .waitingForPlane
            )

            ARPlaneGuideView(
                guideMessage: "準備完了！STARTをタップ",
                isPlaneDetected: true,
                gameState: .ready
            )
        }
    }
}
