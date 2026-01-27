import SwiftUI
import AsaUIKit

// MARK: - AuthView

struct AuthView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Form
                    formSection

                    // Actions
                    actionSection

                    // Toggle Mode
                    toggleModeSection
                }
                .padding(24)
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "yensign.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AsaColors.coffeeBrown)

            Text("AsaExpenseSync")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.darkSlate)

            Text("複数デバイスで収支を同期")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
        }
        .padding(.top, 40)
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 16) {
            // Display Name (Sign Up only)
            if authViewModel.isSignUpMode {
                VStack(alignment: .leading, spacing: 8) {
                    Text("表示名")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    TextField("表示名（任意）", text: $authViewModel.displayName)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.name)
                }
            }

            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("メールアドレス")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                TextField("example@email.com", text: $authViewModel.email)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                if let error = authViewModel.emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("パスワード")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)

                SecureField("6文字以上", text: $authViewModel.password)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textContentType(authViewModel.isSignUpMode ? .newPassword : .password)

                if let error = authViewModel.passwordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 16) {
            // Error Message
            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // Main Button
            AsaButton(
                title: authViewModel.isSignUpMode ? "アカウント作成" : "ログイン",
                action: {
                    Task {
                        if authViewModel.isSignUpMode {
                            await authViewModel.signUp()
                        } else {
                            await authViewModel.signIn()
                        }
                    }
                },
                isEnabled: !authViewModel.isLoading
            )

            // Forgot Password (Sign In only)
            if !authViewModel.isSignUpMode {
                Button(action: {
                    Task {
                        await authViewModel.sendPasswordReset()
                    }
                }) {
                    Text("パスワードを忘れた方")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
        }
    }

    // MARK: - Toggle Mode Section

    private var toggleModeSection: some View {
        HStack {
            Text(authViewModel.isSignUpMode ? "すでにアカウントをお持ちの方" : "アカウントをお持ちでない方")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)

            Button(action: {
                authViewModel.toggleAuthMode()
            }) {
                Text(authViewModel.isSignUpMode ? "ログイン" : "新規登録")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AsaColors.coffeeBrown)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - RoundedTextFieldStyle

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AsaColors.mutedSage.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environmentObject(AuthViewModel(authService: MockAuthService()))
}
