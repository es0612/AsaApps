import SwiftUI
import AsaFamilyTreeKit
import AsaUIKit

struct MemberNodeView: View {
    // MARK: - Properties

    let node: TreeNode
    var dimmed: Bool = false
    var isSelected: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            avatar
            nameLabel
            lifeSpanLabel
        }
        .padding(8)
        .frame(width: node.size.width, height: node.size.height)
        .background(cardBackground)
        .overlay(cardBorder)
        .overlay(alignment: .topLeading) {
            if !node.member.isAlive {
                deceasedBadge
                    .padding(.leading, 4)
                    .padding(.top, 4)
            }
        }
        .saturation(saturationAmount)
        .opacity(overallOpacity)
        .animation(.easeInOut(duration: 0.2), value: dimmed)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Subviews

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(node.member.gender.nodeBackgroundColor)
                .frame(width: 44, height: 44)

            Image(systemName: node.member.gender.iconName)
                .font(.title2)
                .foregroundStyle(AsaColors.coffeeBrown)

            Circle()
                .strokeBorder(node.member.gender.nodeBorderColor, lineWidth: 2)
                .frame(width: 44, height: 44)
        }
    }

    private var nameLabel: some View {
        Text(node.member.fullName)
            .font(.caption)
            .fontWeight(.medium)
            .lineLimit(1)
            .foregroundStyle(AsaColors.darkSlate)
    }

    @ViewBuilder
    private var lifeSpanLabel: some View {
        if !node.member.lifeSpanString.isEmpty {
            Text(node.member.lifeSpanString)
                .font(.caption2)
                .foregroundStyle(AsaColors.mocha.opacity(0.7))
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(AsaColors.cardBackground)
            .shadow(
                color: AsaColors.mocha.opacity(0.15),
                radius: isSelected ? 6 : 3,
                x: 0,
                y: 1
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder(
                isSelected
                    ? AsaColors.coffeeBrown
                    : node.member.gender.nodeBorderColor,
                lineWidth: isSelected ? 2.5 : 2
            )
    }

    private var deceasedBadge: some View {
        Text("没")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(AsaColors.mocha)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(AsaColors.softCream)
            )
    }

    // MARK: - Style Helpers

    private var saturationAmount: Double {
        var value: Double = 1.0
        if !node.member.isAlive { value *= 0.2 }
        if dimmed { value *= 0.3 }
        return value
    }

    private var overallOpacity: Double {
        var value: Double = 1.0
        if !node.member.isAlive { value *= 0.85 }
        if dimmed { value *= 0.35 }
        return value
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // 男性メンバー（存命）
        MemberNodeView(
            node: TreeNode(
                member: FamilyMember(
                    firstName: "太郎",
                    lastName: "山田",
                    gender: .male,
                    birthDate: Calendar.current.date(from: DateComponents(year: 1950))
                ),
                position: .zero,
                size: CGSize(width: 120, height: 80),
                generation: 0
            )
        )

        // 女性メンバー（故人）
        MemberNodeView(
            node: TreeNode(
                member: FamilyMember(
                    firstName: "花子",
                    lastName: "山田",
                    gender: .female,
                    birthDate: Calendar.current.date(from: DateComponents(year: 1955)),
                    deathDate: Calendar.current.date(from: DateComponents(year: 2020))
                ),
                position: .zero,
                size: CGSize(width: 120, height: 80),
                generation: 0
            )
        )

        // 選択中（存命）
        MemberNodeView(
            node: TreeNode(
                member: FamilyMember(
                    firstName: "一郎",
                    lastName: "山田",
                    gender: .male,
                    birthDate: Calendar.current.date(from: DateComponents(year: 1980))
                ),
                position: .zero,
                size: CGSize(width: 120, height: 80),
                generation: 1
            ),
            isSelected: true
        )

        // 半透明（ハイライト外）
        MemberNodeView(
            node: TreeNode(
                member: FamilyMember(
                    firstName: "由美",
                    lastName: "鈴木",
                    gender: .female,
                    birthDate: Calendar.current.date(from: DateComponents(year: 1985))
                ),
                position: .zero,
                size: CGSize(width: 120, height: 80),
                generation: 1
            ),
            dimmed: true
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
