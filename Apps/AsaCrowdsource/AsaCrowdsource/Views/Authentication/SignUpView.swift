//
//  SignUpView.swift
//  AsaCrowdsource
//
//  サインアップ画面
//

import SwiftUI
import AsaUIKit

struct SignUpView: View {
    // MARK: - Properties

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }

    private var passwordsMatch: Bool {
        password == confirmPassword || confirmPassword.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    headerSection

                    // 入力フォーム
                    formSection

                    // エラーメッセージ
                    if let error = authViewModel.errorMessage {
                        errorMessageView(error)
                    }

                    // サインアップボタン
                    signUpButton
                }
                .padding(24)
            }
            .background(Color(AsaColors.softCream).opacity(0.3))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color(AsaColors.coffeeBrown))
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(AsaColors.coffeeBrown))

            Text("新規アカウント作成")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(AsaColors.darkSlate))
        }
        .padding(.top, 20)
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            // 表示名
            VStack(alignment: .leading, spacing: 8) {
                Text("表示名")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(AsaColors.darkSlate))

                TextField("例：パパ、ママ", text: $displayName)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.name)
            }

            // メールアドレス
            VStack(alignment: .leading, spacing: 8) {
                Text("メールアドレス")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(AsaColors.darkSlate))

                TextField("example@email.com", text: $email)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            // パスワード
            VStack(alignment: .leading, spacing: 8) {
                Text("パスワード")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(AsaColors.darkSlate))

                SecureField("6文字以上", text: $password)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.newPassword)

                if !password.isEmpty && password.count < 6 {
                    Text("パスワードは6文字以上で入力してください")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // パスワード確認
            VStack(alignment: .leading, spacing: 8) {
                Text("パスワード（確認）")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(AsaColors.darkSlate))

                SecureField("もう一度入力", text: $confirmPassword)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.newPassword)

                if !passwordsMatch {
                    Text("パスワードが一致しません")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }

    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    private var signUpButton: some View {
        Button {
            Task {
                await authViewModel.signUp(
                    email: email,
                    password: password,
                    displayName: displayName
                )
                if authViewModel.isSignedIn {
                    dismiss()
                }
            }
        } label: {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("アカウントを作成")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(AsaColors.coffeeBrown))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || authViewModel.isLoading)
        .opacity(isFormValid ? 1.0 : 0.6)
    }
}

// MARK: - Preview

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
