import Foundation
import SwiftUI
import AuthenticationServices

// MARK: - Auth View Model

@MainActor
@Observable
final class AuthViewModel {
    // MARK: - Dependencies

    private let authService: AuthService

    // MARK: - State

    private(set) var currentUser: User?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private var authStateListener: Any?

    // MARK: - Computed Properties

    var isAuthenticated: Bool {
        currentUser != nil
    }

    var displayName: String {
        currentUser?.displayNameOrEmail ?? ""
    }

    // MARK: - Initializer

    init(authService: AuthService) {
        self.authService = authService
        setupAuthStateListener()
    }

    deinit {
        // リスナー解除（MainActorコンテキスト外で呼ばれる可能性あり）
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        authStateListener = authService.addAuthStateListener { [weak self] user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    // MARK: - Sign In with Apple

    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        do {
            switch result {
            case .success(let authorization):
                try await authService.signInWithApple(authorization: authorization)
            case .failure(let error):
                throw AuthError.signInFailed(error.localizedDescription)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try authService.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Update Profile

    func updateDisplayName(_ name: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.updateUserProfile(displayName: name, photoURL: nil)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - FCM Token

    func updateFCMToken(_ token: String) async {
        do {
            try await authService.updateFCMToken(token)
        } catch {
            print("FCM token update failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }
}
