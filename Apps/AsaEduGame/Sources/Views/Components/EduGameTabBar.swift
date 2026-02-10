import SwiftUI
import AsaUIKit

// MARK: - カスタムタブバー

/// 子供向けの大きめアイコンのカスタムタブバー
/// 3タブ: ホーム、しんちょく、プロフィール
struct EduGameTabBar: View {

    // MARK: - Properties

    @Binding var selectedTab: Int

    // MARK: - Constants

    /// タブ項目定義
    private let tabs: [(icon: String, label: String, index: Int)] = [
        ("house.fill", "ホーム", 0),
        ("chart.bar.fill", "しんちょく", 1),
        ("person.fill", "プロフィール", 2)
    ]

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.index) { tab in
                tabButton(
                    icon: tab.icon,
                    label: tab.label,
                    index: tab.index
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
        )
    }

    // MARK: - タブボタン

    private func tabButton(icon: String, label: String, index: Int) -> some View {
        let isSelected = selectedTab == index

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 6) {
                // アイコン（大きめ）
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? AsaColors.coffeeBrown : AsaColors.mutedSage)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                // ラベル
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? AsaColors.coffeeBrown : AsaColors.mutedSage)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)タブ")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        EduGameTabBar(selectedTab: .constant(0))
    }
}
