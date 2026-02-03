//
//  SettingsView.swift
//  AsaCrowdsource
//
//  設定画面
//

import SwiftUI
import AsaUIKit

struct SettingsView: View {
    // MARK: - Properties

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var familyViewModel: FamilyGroupViewModel

    @State private var showLogoutAlert = false
    @State private var showLeaveGroupAlert = false
    @State private var showDeleteGroupAlert = false
    @State private var editingDisplayName = false
    @State private var newDisplayName = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // プロフィールセクション
                profileSection

                // グループセクション
                if familyViewModel.hasGroup {
                    groupSection
                }

                // アプリ情報セクション
                appInfoSection

                // ログアウトセクション
                logoutSection
            }
            .navigationTitle("設定")
            .alert("表示名を変更", isPresented: $editingDisplayName) {
                TextField("表示名", text: $newDisplayName)
                Button("キャンセル", role: .cancel) {}
                Button("保存") {
                    if !newDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        authViewModel.updateDisplayName(newDisplayName)
                    }
                }
            }
            .alert("ログアウト", isPresented: $showLogoutAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("ログアウト", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("ログアウトしますか？")
            }
            .alert("グループから離脱", isPresented: $showLeaveGroupAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("離脱", role: .destructive) {
                    Task {
                        await familyViewModel.leaveGroup()
                    }
                }
            } message: {
                Text("「\(familyViewModel.groupName)」から離脱しますか？")
            }
            .alert("グループを削除", isPresented: $showDeleteGroupAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    Task {
                        await familyViewModel.deleteGroup()
                    }
                }
            } message: {
                Text("「\(familyViewModel.groupName)」を削除しますか？\nメンバー全員がグループから外れます。")
            }
        }
    }

    // MARK: - Subviews

    private var profileSection: some View {
        Section {
            // ユーザー情報
            HStack(spacing: 12) {
                // アバター
                Circle()
                    .fill(Color(AsaColors.coffeeBrown).opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String((authViewModel.currentUser?.displayName ?? "?").prefix(1)))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(authViewModel.currentUser?.displayName ?? "ゲスト")
                        .font(.headline)
                        .foregroundColor(Color(AsaColors.darkSlate))

                    if let email = authViewModel.currentUser?.email, !email.isEmpty {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(Color(AsaColors.mutedSage))
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)

            // 表示名変更
            Button {
                newDisplayName = authViewModel.currentUser?.displayName ?? ""
                editingDisplayName = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                    Text("表示名を変更")
                        .foregroundColor(Color(AsaColors.darkSlate))
                }
            }
        } header: {
            Text("プロフィール")
        }
    }

    private var groupSection: some View {
        Section {
            // 現在のグループ
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(Color(AsaColors.coffeeBrown))
                VStack(alignment: .leading) {
                    Text(familyViewModel.groupName)
                        .foregroundColor(Color(AsaColors.darkSlate))
                    Text("\(familyViewModel.memberCount)人のメンバー")
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
            }

            // 招待コード
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(Color(AsaColors.coffeeBrown))
                Text("招待コード")
                    .foregroundColor(Color(AsaColors.darkSlate))
                Spacer()
                Text(familyViewModel.inviteCode)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color(AsaColors.mutedSage))
            }

            // グループ離脱
            if !familyViewModel.isOwner {
                Button {
                    showLeaveGroupAlert = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.orange)
                        Text("グループから離脱")
                            .foregroundColor(.orange)
                    }
                }
            }

            // グループ削除（オーナーのみ）
            if familyViewModel.isOwner {
                Button {
                    showDeleteGroupAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("グループを削除")
                            .foregroundColor(.red)
                    }
                }
            }
        } header: {
            Text("グループ")
        }
    }

    private var appInfoSection: some View {
        Section {
            // バージョン
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(Color(AsaColors.coffeeBrown))
                Text("バージョン")
                    .foregroundColor(Color(AsaColors.darkSlate))
                Spacer()
                Text("1.0.0")
                    .foregroundColor(Color(AsaColors.mutedSage))
            }

            // アプリについて
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(AsaColors.coffeeBrown))
                VStack(alignment: .leading, spacing: 4) {
                    Text("AsaCrowdsource")
                        .foregroundColor(Color(AsaColors.darkSlate))
                    Text("家族でアイデアを共有するアプリ")
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
            }
        } header: {
            Text("アプリ情報")
        }
    }

    private var logoutSection: some View {
        Section {
            Button {
                showLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                    Text("ログアウト")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(FamilyGroupViewModel())
}
