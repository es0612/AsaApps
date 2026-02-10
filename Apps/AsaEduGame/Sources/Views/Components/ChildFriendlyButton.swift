import SwiftUI
import AsaUIKit

// MARK: - 子供向けボタン

/// 子供向けの大きなタップ領域ボタン
/// 最小60x60pt、丸角、大きめフォント、タップアニメーション
struct ChildFriendlyButton: View {

    // MARK: - Properties

    /// ボタンタイトル
    let title: String

    /// ボタン色
    var color: Color = AsaColors.coffeeBrown

    /// アイコン名（SF Symbols、オプション）
    var icon: String?

    /// ボタンが有効か
    var isEnabled: Bool = true

    /// タップアクション
    let action: () -> Void

    // MARK: - State

    @State private var isPressed: Bool = false

    // MARK: - Body

    var body: some View {
        Button {
            // タップフィードバックアニメーション
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            // 元に戻す
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            action()
        } label: {
            HStack(spacing: 8) {
                // アイコン（あれば）
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                }

                // タイトル
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .background(
                isEnabled
                    ? color
                    : Color.gray.opacity(0.4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: isEnabled ? color.opacity(0.3) : .clear,
                radius: 4,
                y: 3
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ChildFriendlyButton(
            title: "はじめる",
            action: {}
        )

        ChildFriendlyButton(
            title: "つぎへ",
            color: AsaColors.mutedSage,
            icon: "arrow.right",
            action: {}
        )

        ChildFriendlyButton(
            title: "おやすみ",
            color: AsaColors.mocha,
            isEnabled: false,
            action: {}
        )

        ChildFriendlyButton(
            title: "さんすう",
            color: AsaColors.darkSlate,
            icon: "plus.circle.fill",
            action: {}
        )
    }
    .padding()
}
