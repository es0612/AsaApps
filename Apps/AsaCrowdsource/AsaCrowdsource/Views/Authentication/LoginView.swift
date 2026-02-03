//
//  LoginView.swift
//  AsaCrowdsource
//
//  ログイン画面
//

import SwiftUI
import AsaUIKit

struct LoginView: View {
    // MARK: - Properties

    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // ロゴ・タイトル
                    headerSection

                    // 入力フォーム
                    formSection

                    // エラーメッセージ
                    if let error = authViewModel.errorMessage {
                        errorMessageView(error)
                    }

                    // ログインボタン
                    loginButton

                    // 区切り線
                    divider

                    // ゲストログイン
                    guestLoginButton

                    // サインアップリンク
                    signUpLink
                }
                .padding(24)
            }
            .background(Color(AsaColors.softCream).opacity(0.3))
            .navigationBarHidden(true)
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(AsaColors.coffeeBrown))

            Text("家族のアイデア共有")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(AsaColors.darkSlate))

            Text("みんなのアイデアを集めよう")
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.mutedSage))
        }
        .padding(.top, 40)
    }

    private var formSection: some View {
        VStack(spacing: 16) {
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
                    .textContentType(.password)
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

    private var loginButton: some View {
        Button {
            Task {
                await authViewModel.signIn(email: email, password: password)
            }
        } label: {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("ログイン")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(AsaColors.coffeeBrown))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
    }

    private var divider: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(AsaColors.mutedSage).opacity(0.3))

            Text("または")
                .font(.footnote)
                .foregroundColor(Color(AsaColors.mutedSage))

            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(AsaColors.mutedSage).opacity(0.3))
        }
    }

    private var guestLoginButton: some View {
        Button {
            authViewModel.signInAsGuest()
        } label: {
            HStack {
                Image(systemName: "person.fill.questionmark")
                Text("ゲストとして試す")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(AsaColors.mutedSage).opacity(0.2))
            .foregroundColor(Color(AsaColors.darkSlate))
            .cornerRadius(12)
        }
    }

    private var signUpLink: some View {
        HStack {
            Text("アカウントをお持ちでない方は")
                .font(.footnote)
                .foregroundColor(Color(AsaColors.mutedSage))

            Button {
                showSignUp = true
            } label: {
                Text("新規登録")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(AsaColors.coffeeBrown))
            }
        }
    }
}

// MARK: - Custom TextField Style

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(AsaColors.mutedSage).opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
