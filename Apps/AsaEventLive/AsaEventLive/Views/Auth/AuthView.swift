import SwiftUI
import AsaUIKit
#if FIREBASE_ENABLED
import AuthenticationServices
#endif

// MARK: - AuthView

struct AuthView: View {
    // MARK: - Properties

    @Environment(AuthViewModel.self) private var authViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [AsaColors.coffeeBrown.opacity(0.8), AsaColors.mocha],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // アプリロゴ・タイトル
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .shadow(radius: 10)

                    Text("AsaEventLive")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("家族や友人とイベントを\nリアルタイムで共有")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // サインインボタン
                VStack(spacing: 16) {
                    #if FIREBASE_ENABLED
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            Task {
                                await authViewModel.signInWithApple(credential: authorization.credential)
                            }
                        case .failure(let error):
                            print("Sign in with Apple failed: \(error.localizedDescription)")
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                    #endif

                    // デモモードボタン
                    Button {
                        authViewModel.signInAsDemo()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill.questionmark")
                            Text("デモモードで始める")
                        }
                        .font(.headline)
                        .foregroundStyle(AsaColors.coffeeBrown)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal, 32)

                // エラーメッセージ
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer()
                    .frame(height: 40)

                // フッター
                Text("© 2025 AsaApps")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .overlay {
            if authViewModel.isProcessing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let dataService = MockEventDataService()
    let authViewModel = AuthViewModel(dataService: dataService)

    return AuthView()
        .environment(authViewModel)
}
