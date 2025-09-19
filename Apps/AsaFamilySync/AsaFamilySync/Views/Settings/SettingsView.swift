import SwiftUI
import AsaUIKit

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var familyViewModel = FamilyGroupViewModel()
    @State private var showSignOutAlert = false
    @State private var showLeaveGroupAlert = false

    var body: some View {
        NavigationStack {
            List {
                // ユーザー情報セクション
                Section {
                    HStack {
                        Circle()
                            .fill(AsaColors.coffeeBrown)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(authViewModel.currentUser?.displayName.prefix(1).uppercased() ?? "?")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.displayName ?? "ユーザー名")
                                .font(.body)
                                .fontWeight(.medium)
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // 家族グループ設定
                Section("家族グループ") {
                    if let group = familyViewModel.familyGroup {
                        HStack {
                            Label("グループ名", systemImage: "house")
                            Spacer()
                            Text(group.name)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Label("招待コード", systemImage: "key")
                            Spacer()
                            Text(group.inviteCode)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Button(action: { showLeaveGroupAlert = true }) {
                            Label("グループを退出", systemImage: "arrow.right.square")
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("グループに参加していません")
                            .foregroundColor(.secondary)
                    }
                }

                // 通知設定
                Section("通知設定") {
                    Toggle(isOn: .constant(true)) {
                        Label("プッシュ通知", systemImage: "bell")
                    }

                    Toggle(isOn: .constant(true)) {
                        Label("リマインダー", systemImage: "alarm")
                    }

                    Toggle(isOn: .constant(false)) {
                        Label("メール通知", systemImage: "envelope")
                    }
                }

                // アプリ情報
                Section("アプリ情報") {
                    HStack {
                        Label("バージョン", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://asaapps.com/privacy")!) {
                        Label("プライバシーポリシー", systemImage: "lock")
                    }

                    Link(destination: URL(string: "https://asaapps.com/terms")!) {
                        Label("利用規約", systemImage: "doc.text")
                    }
                }

                // アカウント操作
                Section {
                    Button(action: { showSignOutAlert = true }) {
                        Label("サインアウト", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let familyId = authViewModel.currentUser?.familyId {
                    familyViewModel.listenToFamilyGroup(groupId: familyId)
                }
            }
        }
        .alert("サインアウト", isPresented: $showSignOutAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("サインアウト", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("本当にサインアウトしますか？")
        }
        .alert("グループを退出", isPresented: $showLeaveGroupAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("退出", role: .destructive) {
                Task {
                    await familyViewModel.leaveFamilyGroup()
                }
            }
        } message: {
            Text("本当にこの家族グループから退出しますか？")
        }
    }
}