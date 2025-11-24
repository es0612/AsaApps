import SwiftUI
import AsaUIKit

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isSignUp: Bool

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var agreedToTerms = false

    var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreedToTerms
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // ロゴとタイトル
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 80))
                            .foregroundColor(AsaColors.coffeeBrown)

                        Text("新規アカウント作成")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("家族の予定を共有しましょう")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // 登録フォーム
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("表示名")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("お名前", text: $displayName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.name)
                        }

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
                            Text("パスワード（6文字以上）")
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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード（確認）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("パスワードを再入力", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.password)

                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("パスワードが一致しません")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        // 利用規約同意
                        HStack {
                            Toggle("", isOn: $agreedToTerms)
                                .toggleStyle(SwitchToggleStyle(tint: AsaColors.coffeeBrown))
                                .labelsHidden()

                            Text("利用規約とプライバシーポリシーに同意する")
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        // エラーメッセージ
                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        // 登録ボタン
                        AsaButton(
                            title: "アカウントを作成",
                            action: {
                                Task {
                                    await authViewModel.signUp(
                                        email: email,
                                        password: password,
                                        displayName: displayName
                                    )
                                }
                            },
                            color: AsaColors.coffeeBrown,
                            isEnabled: !authViewModel.isLoading && isFormValid
                        )
                    }
                    .padding(.horizontal, 30)

                    Divider()
                        .padding(.horizontal, 30)

                    // ログインへ
                    VStack(spacing: 16) {
                        Text("既にアカウントをお持ちの方")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: { isSignUp = false }) {
                            HStack {
                                Image(systemName: "arrow.left.circle.fill")
                                Text("ログインに戻る")
                            }
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(AsaColors.mocha)
                        }
                    }

                    Spacer(minLength: 50)
                }
            }
            .navigationBarHidden(true)
        }
    }
}