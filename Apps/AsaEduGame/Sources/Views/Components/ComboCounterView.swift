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
            if combo >= 3 {
                HStack(spacing: 1) {
                    ForEach(0..<flameCount, id: \.self) { _ in
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(comboColor)
                    }
                }
                .scaleEffect(isAnimating ? 1.2 : 1.0)
            }

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

    /// コンボ数に応じた色（ブランドカラー基調）
    private var comboColor: Color {
        switch combo {
        case 0..<3:
            return AsaColors.mutedSage
        case 3..<5:
            return AsaColors.coffeeBrown
        case 5..<10:
            return AsaColors.mocha
        default:
            return AsaColors.darkSlate
        }
    }

    /// コンボ数に応じた炎アイコンの数（1-3個）
    private var flameCount: Int {
        switch combo {
        case 3..<5: return 1
        case 5..<10: return 2
        default: return 3
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
