import SwiftUI
import AsaUIKit

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel

    @State private var showingLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                accountSection

                // Sync Section
                syncSection

                // App Info Section
                appInfoSection

                // Logout Section
                logoutSection
            }
            .navigationTitle("設定")
            .alert("ログアウト", isPresented: $showingLogoutConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("ログアウト", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("本当にログアウトしますか？")
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("アカウント") {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AsaColors.coffeeBrown.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Text(userInitials)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AsaColors.coffeeBrown)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(authViewModel.currentUser?.displayName ?? "ユーザー")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Text(authViewModel.currentUser?.email ?? "")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                Spacer()
            }
            .padding(.vertical, 4)

            HStack {
                Text("デバイスID")
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Text(String(authViewModel.currentDeviceId.prefix(8)) + "...")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        Section("同期") {
            HStack {
                Text("同期ステータス")
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                SyncStatusBadge(status: expenseViewModel.syncMetadata.syncStatus)
            }

            HStack {
                Text("最終同期")
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Text(expenseViewModel.syncMetadata.lastSyncDescription)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }

            HStack {
                Text("取引数")
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Text("\(expenseViewModel.transactions.count)件")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }

            Button(action: {
                Task {
                    guard let userId = authViewModel.currentUser?.id else { return }
                    await expenseViewModel.loadData(userId: userId)
                }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("今すぐ同期")
                }
            }
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section("アプリ情報") {
            HStack {
                Text("バージョン")
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Text("1.0.0")
                    .foregroundColor(AsaColors.mutedSage)
            }

            HStack {
                Text("ビルド")
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Text("1")
                    .foregroundColor(AsaColors.mutedSage)
            }

            Link(destination: URL(string: "https://github.com/yourusername/AsaApps")!) {
                HStack {
                    Text("GitHub")
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
        }
    }

    // MARK: - Logout Section

    private var logoutSection: some View {
        Section {
            Button(role: .destructive, action: {
                showingLogoutConfirmation = true
            }) {
                HStack {
                    Spacer()
                    Text("ログアウト")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helpers

    private var userInitials: String {
        guard let displayName = authViewModel.currentUser?.displayName, !displayName.isEmpty else {
            return authViewModel.currentUser?.email.prefix(1).uppercased() ?? "U"
        }
        return displayName.prefix(1).uppercased()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel(authService: MockAuthService()))
        .environmentObject(ExpenseViewModel(dataService: MockExpenseDataService()))
}
