import SwiftUI
import AsaUIKit

struct InviteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let familyGroup: FamilyGroup?

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AsaColors.coffeeBrown)
                    .padding(.top, 40)

                Text("家族を招待")
                    .font(.title2)
                    .fontWeight(.bold)

                if let group = familyGroup {
                    VStack(spacing: 20) {
                        Text("以下の招待コードを家族に共有してください")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            ForEach(Array(group.inviteCode), id: \.self) { char in
                                Text(String(char))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .frame(width: 45, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AsaColors.softCream)
                                    )
                                    .foregroundColor(AsaColors.darkSlate)
                            }
                        }

                        AsaButton(
                            title: "コードをコピー",
                            action: {
                                UIPasteboard.general.string = group.inviteCode
                                dismiss()
                            },
                            color: AsaColors.coffeeBrown
                        )
                        .padding(.horizontal, 30)
                    }
                }

                Spacer()
            }
            .navigationTitle("招待")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ManageMembersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var familyViewModel: FamilyGroupViewModel
    let currentUserId: String

    var body: some View {
        NavigationStack {
            List {
                ForEach(familyViewModel.familyMembers) { member in
                    if member.userId != currentUserId {
                        HStack {
                            Circle()
                                .fill(Color(hex: member.color))
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Text(member.name.prefix(1).uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading) {
                                Text(member.name)
                                    .font(.body)
                                Text(member.role.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Menu {
                                if member.role != .admin {
                                    Button {
                                        Task {
                                            await familyViewModel.updateMemberRole(
                                                memberId: member.userId,
                                                newRole: .admin
                                            )
                                        }
                                    } label: {
                                        Label("管理者にする", systemImage: "shield")
                                    }
                                } else {
                                    Button {
                                        Task {
                                            await familyViewModel.updateMemberRole(
                                                memberId: member.userId,
                                                newRole: .member
                                            )
                                        }
                                    } label: {
                                        Label("メンバーにする", systemImage: "person")
                                    }
                                }

                                Divider()

                                Button(role: .destructive) {
                                    Task {
                                        await familyViewModel.removeMember(memberId: member.userId)
                                    }
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(AsaColors.mocha)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("メンバー管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}