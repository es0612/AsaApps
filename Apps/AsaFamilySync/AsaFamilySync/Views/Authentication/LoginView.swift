import SwiftUI
import AsaUIKit

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showResetPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // ロゴとタイトル
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 80))
                            .foregroundColor(AsaColors.coffeeBrown)

                        Text("AsaFamilySync")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("家族の予定をクラウド同期")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)

                    // ログインフォーム
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メールアドレス")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("email@example.com", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                if showPassword {
                                    TextField("パスワード", text: $password)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                } else {
                                    SecureField("パスワード", text: $password)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        // エラーメッセージ
                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        // ログインボタン
                        AsaButton(
                            title: "ログイン",
                            action: {
                                Task {
                                    await authViewModel.signIn(email: email, password: password)
                                }
                            },
                            color: AsaColors.coffeeBrown,
                            isLoading: authViewModel.isLoading
                        )
                        .disabled(email.isEmpty || password.isEmpty)

                        // パスワードリセット
                        Button("パスワードを忘れた方はこちら") {
                            showResetPassword = true
                        }
                        .font(.caption)
                        .foregroundColor(AsaColors.mocha)
                    }
                    .padding(.horizontal, 30)

                    Divider()
                        .padding(.horizontal, 30)

                    // サインアップへ
                    VStack(spacing: 16) {
                        Text("アカウントをお持ちでない方")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        AsaButton(
                            title: "新規登録",
                            action: { isSignUp = true },
                            color: AsaColors.mutedSage,
                            icon: "person.badge.plus"
                        )
                        .padding(.horizontal, 30)
                    }

                    Spacer(minLength: 50)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView()
        }
    }
}

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AsaColors.coffeeBrown)
                    .padding(.top, 40)

                Text("パスワードをリセット")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("登録済みのメールアドレスにパスワードリセット用のリンクを送信します")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("メールアドレス")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("email@example.com", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                .padding(.horizontal, 30)

                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(errorMessage.contains("送信しました") ? .green : .red)
                        .padding(.horizontal)
                }

                AsaButton(
                    title: "リセットメールを送信",
                    action: {
                        Task {
                            await authViewModel.resetPassword(email: email)
                        }
                    },
                    color: AsaColors.coffeeBrown,
                    isLoading: authViewModel.isLoading
                )
                .disabled(email.isEmpty)
                .padding(.horizontal, 30)

                Spacer()
            }
            .navigationTitle("パスワードリセット")
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