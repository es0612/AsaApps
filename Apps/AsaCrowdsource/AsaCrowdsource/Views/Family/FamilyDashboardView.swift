//
//  FamilyDashboardView.swift
//  AsaCrowdsource
//
//  家族グループダッシュボード画面
//

import SwiftUI
import AsaUIKit

struct FamilyDashboardView: View {
    // MARK: - Properties

    @EnvironmentObject private var familyViewModel: FamilyGroupViewModel
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var showInviteCode = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if familyViewModel.hasGroup {
                    groupDashboard
                } else {
                    noGroupView
                }
            }
            .navigationTitle("グループ")
            .toolbar {
                if familyViewModel.hasGroup {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showInviteCode = true
                            } label: {
                                Label("招待コード", systemImage: "person.badge.plus")
                            }

                            if familyViewModel.userGroups.count > 1 {
                                Menu("グループを切り替え") {
                                    ForEach(familyViewModel.userGroups) { group in
                                        Button {
                                            Task {
                                                await familyViewModel.switchGroup(to: group)
                                            }
                                        } label: {
                                            if group.id == familyViewModel.currentGroup?.id {
                                                Label(group.name, systemImage: "checkmark")
                                            } else {
                                                Text(group.name)
                                            }
                                        }
                                    }
                                }
                            }

                            Divider()

                            Button {
                                showCreateGroup = true
                            } label: {
                                Label("新しいグループを作成", systemImage: "plus.circle")
                            }

                            Button {
                                showJoinGroup = true
                            } label: {
                                Label("別のグループに参加", systemImage: "person.2.badge.gearshape")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Color(AsaColors.coffeeBrown))
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateFamilyView()
            }
            .sheet(isPresented: $showJoinGroup) {
                JoinFamilyView()
            }
            .sheet(isPresented: $showInviteCode) {
                InviteCodeView()
            }
        }
    }

    // MARK: - Subviews

    private var groupDashboard: some View {
        ScrollView {
            VStack(spacing: 24) {
                // グループ情報カード
                groupInfoCard

                // メンバーセクション
                membersSection

                // 統計セクション
                statisticsSection
            }
            .padding()
        }
        .background(Color(AsaColors.softCream).opacity(0.3))
    }

    private var groupInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(familyViewModel.groupName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(AsaColors.darkSlate))

                    if familyViewModel.isOwner {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            Text("オーナー")
                                .font(.caption)
                        }
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                    }
                }

                Spacer()

                Image(systemName: "person.3.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(AsaColors.coffeeBrown).opacity(0.3))
            }

            Divider()

            HStack {
                VStack {
                    Text("\(familyViewModel.memberCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                    Text("メンバー")
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }

                Spacer()

                Button {
                    showInviteCode = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("招待する")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(AsaColors.coffeeBrown))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("メンバー")
                .font(.headline)
                .foregroundColor(Color(AsaColors.darkSlate))

            LazyVStack(spacing: 8) {
                ForEach(familyViewModel.members) { member in
                    MemberRowView(member: member)
                }
            }
        }
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("グループ情報")
                .font(.headline)
                .foregroundColor(Color(AsaColors.darkSlate))

            HStack(spacing: 12) {
                StatCard(
                    title: "グループ数",
                    value: "\(familyViewModel.userGroups.count)",
                    icon: "folder.fill",
                    color: Color(AsaColors.coffeeBrown)
                )

                StatCard(
                    title: "メンバー数",
                    value: "\(familyViewModel.memberCount)",
                    icon: "person.2.fill",
                    color: Color(AsaColors.mutedSage)
                )
            }
        }
    }

    private var noGroupView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(AsaColors.mutedSage).opacity(0.3))

            VStack(spacing: 8) {
                Text("グループがありません")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(AsaColors.darkSlate))

                Text("家族グループを作成するか、\n招待コードで参加しましょう")
                    .font(.subheadline)
                    .foregroundColor(Color(AsaColors.mutedSage))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    showCreateGroup = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("グループを作成")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(AsaColors.coffeeBrown))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button {
                    showJoinGroup = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("招待コードで参加")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(AsaColors.mutedSage).opacity(0.2))
                    .foregroundColor(Color(AsaColors.darkSlate))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Member Row View

struct MemberRowView: View {
    let member: LocalMember

    var body: some View {
        HStack(spacing: 12) {
            // アバター
            Circle()
                .fill(Color(AsaColors.coffeeBrown).opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(member.displayName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                )

            // 名前とロール
            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(AsaColors.darkSlate))

                HStack(spacing: 4) {
                    Text(member.role.emoji)
                        .font(.caption2)
                    Text(member.role.displayName)
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Stat Card View

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
                .foregroundColor(Color(AsaColors.darkSlate))

            Text(title)
                .font(.caption)
                .foregroundColor(Color(AsaColors.mutedSage))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    FamilyDashboardView()
        .environmentObject(FamilyGroupViewModel())
}
