import SwiftUI
import AsaUIKit

struct FamilyDashboardView: View {
    @StateObject private var familyViewModel = FamilyGroupViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showInviteSheet = false
    @State private var showManageSheet = false

    var currentUserRole: MemberRole? {
        guard let userId = authViewModel.currentUser?.uid else { return nil }
        return familyViewModel.familyMembers.first { $0.userId == userId }?.role
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // グループ情報カード
                    if let group = familyViewModel.familyGroup {
                        GroupInfoCard(
                            group: group,
                            membersCount: familyViewModel.familyMembers.count,
                            onInvite: { showInviteSheet = true }
                        )
                    }

                    // メンバーリスト
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("メンバー")
                                .font(.title2)
                                .fontWeight(.bold)

                            Spacer()

                            if currentUserRole?.canManageMembers == true {
                                Button(action: { showManageSheet = true }) {
                                    Label("管理", systemImage: "person.badge.shield.checkmark")
                                        .font(.caption)
                                        .foregroundColor(AsaColors.mocha)
                                }
                            }
                        }

                        ForEach(familyViewModel.familyMembers) { member in
                            MemberCard(member: member)
                        }
                    }
                    .padding(.horizontal)

                    // 統計情報
                    StatsSection(familyViewModel: familyViewModel)
                }
                .padding(.vertical)
            }
            .navigationTitle("家族")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let familyId = authViewModel.currentUser?.familyId {
                    familyViewModel.listenToFamilyGroup(groupId: familyId)
                }
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteSheet(familyGroup: familyViewModel.familyGroup)
        }
        .sheet(isPresented: $showManageSheet) {
            ManageMembersSheet(
                familyViewModel: familyViewModel,
                currentUserId: authViewModel.currentUser?.uid ?? ""
            )
        }
    }
}

struct GroupInfoCard: View {
    let group: FamilyGroup
    let membersCount: Int
    let onInvite: () -> Void

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let description = group.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "house.fill")
                        .font(.title)
                        .foregroundColor(AsaColors.coffeeBrown)
                }

                HStack(spacing: 20) {
                    Label("\(membersCount)/\(group.maxMembers)名", systemImage: "person.3.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("招待コード: \(group.inviteCode)", systemImage: "key.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                AsaButton(
                    title: "メンバーを招待",
                    action: onInvite,
                    color: AsaColors.coffeeBrown,
                    icon: "person.badge.plus",
                    size: .small
                )
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

struct MemberCard: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: member.color))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(member.name.prefix(1).uppercased())
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(member.name)
                        .font(.body)
                        .fontWeight(.medium)

                    if member.role != .member {
                        Text(member.role.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(member.role == .owner ? AsaColors.coffeeBrown : AsaColors.mocha)
                            )
                            .foregroundColor(.white)
                    }
                }

                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let lastActive = member.lastActiveAt {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("最終アクティブ")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(lastActive, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct StatsSection: View {
    @ObservedObject var familyViewModel: FamilyGroupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("活動統計")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            HStack(spacing: 12) {
                StatCard(
                    title: "今月の予定",
                    value: "0",
                    icon: "calendar",
                    color: AsaColors.coffeeBrown
                )

                StatCard(
                    title: "アクティブメンバー",
                    value: "\(familyViewModel.familyMembers.count)",
                    icon: "person.fill",
                    color: AsaColors.mocha
                )

                StatCard(
                    title: "完了タスク",
                    value: "0",
                    icon: "checkmark.circle.fill",
                    color: AsaColors.mutedSage
                )
            }
            .padding(.horizontal)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}