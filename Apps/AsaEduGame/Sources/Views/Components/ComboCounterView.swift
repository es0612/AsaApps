import SwiftUI
import AsaUIKit

// MARK: - コンボカウンター表示

/// コンボ数の大きなアニメーション数字を表示
/// コンボ3以上で炎エフェクトを追加
struct ComboCounterView: View {

    // MARK: - Properties

    /// 現在のコンボ数
    let combo: Int

    // MARK: - State

    @State private var scale: CGFloat = 1.0
    @State private var isAnimating: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            // 炎エフェクト（コンボ3以上）
            if combo >= 3 {
                Text(fireEmoji)
                    .font(.system(size: fireSize))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
            }

            // コンボ数
            Text("\(combo)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(comboColor)

            Text("コンボ")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(comboColor.opacity(0.8))
        }
        .scaleEffect(scale)
        .onChange(of: combo) { _, _ in
            // コンボ更新アニメーション
            withAnimation(.easeInOut(duration: 0.1)) {
                scale = 1.3
            }
            withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                scale = 1.0
            }
        }
        .onAppear {
            // 炎のゆらぎアニメーション
            if combo >= 3 {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .accessibilityLabel("\(combo)コンボ")
    }

    // MARK: - Computed

    /// コンボ数に応じた色
    private var comboColor: Color {
        switch combo {
        case 0..<3:
            return AsaColors.mutedSage
        case 3..<5:
            return .orange
        case 5..<10:
            return .red
        default:
            return .purple
        }
    }

    /// コンボ数に応じた炎の絵文字
    private var fireEmoji: String {
        switch combo {
        case 3..<5:
            return "🔥"
        case 5..<10:
            return "🔥🔥"
        default:
            return "🔥🔥🔥"
        }
    }

    /// 炎のサイズ
    private var fireSize: CGFloat {
        switch combo {
        case 3..<5:
            return 14
        case 5..<10:
            return 12
        default:
            return 10
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ComboCounterView(combo: 2)
        ComboCounterView(combo: 3)
        ComboCounterView(combo: 5)
        ComboCounterView(combo: 10)
        ComboCounterView(combo: 15)
    }
    .padding()
}
