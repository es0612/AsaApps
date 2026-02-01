import SwiftUI
import AsaFamilyTreeKit
import AsaUIKit

struct MemberNodeView: View {
    // MARK: - Properties

    let node: TreeNode

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            // プロフィール画像またはアイコン
            ZStack {
                Circle()
                    .fill(node.member.gender.nodeBackgroundColor)
                    .frame(width: 44, height: 44)

                if node.member.hasProfileImage {
                    // TODO: 画像表示
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(node.member.gender.nodeBorderColor)
                } else {
                    Image(systemName: node.member.gender.iconName)
                        .font(.title2)
                        .foregroundStyle(node.member.gender.nodeBorderColor)
                }

                Circle()
                    .strokeBorder(node.member.gender.nodeBorderColor, lineWidth: 2)
                    .frame(width: 44, height: 44)
            }

            // 名前
            Text(node.member.fullName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundStyle(.primary)

            // 生没年
            if !node.member.lifeSpanString.isEmpty {
                Text(node.member.lifeSpanString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(width: node.size.width, height: node.size.height)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    node.member.isAlive
                        ? node.member.gender.nodeBorderColor
                        : Color.gray.opacity(0.5),
                    lineWidth: 2
                )
        )
        .opacity(node.member.isAlive ? 1.0 : 0.7)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // 男性メンバー
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

        // 女性メンバー
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
    }
    .padding()
}
