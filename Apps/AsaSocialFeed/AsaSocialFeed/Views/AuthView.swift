import SwiftUI
import AuthenticationServices

// MARK: - Auth View

struct AuthView: View {
    // MARK: - Properties

    @Bindable var viewModel: AuthViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            Color("AsaSoftCream")
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // ロゴ・タイトル
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color("AsaCoffeeBrown"))

                    Text("AsaSocialFeed")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("AsaDarkSlate"))

                    Text("朝活コミュニティで\nつながろう")
                        .font(.headline)
                        .foregroundStyle(Color("AsaMocha"))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // サインインボタン
                VStack(spacing: 20) {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task {
                                await viewModel.handleSignInWithApple(result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)

                    Text("Sign in with Appleでログイン")
                        .font(.caption)
                        .foregroundStyle(Color("AsaMutedSage"))
                }

                Spacer()
                    .frame(height: 60)
            }

            // ローディングオーバーレイ
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.clearError() }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Preview

#Preview {
    AuthView(viewModel: AuthViewModel(authService: FirebaseAuthService()))
}
