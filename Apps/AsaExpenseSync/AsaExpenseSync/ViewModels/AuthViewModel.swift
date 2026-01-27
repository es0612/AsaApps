import Foundation
import SwiftUI

// MARK: - AuthViewModel

@MainActor
@Observable
final class AuthViewModel: ObservableObject {
    // MARK: - Properties

    var isAuthenticated: Bool = false
    var currentUser: UserProfile?
    var isLoading: Bool = false
    var errorMessage: String?

    // Form State
    var email: String = ""
    var password: String = ""
    var displayName: String = ""
    var isSignUpMode: Bool = false

    // Validation
    var emailError: String?
    var passwordError: String?

    private let authService: AuthServiceProtocol
    private let deviceId: String

    // MARK: - Initialization

    init(authService: AuthServiceProtocol) {
        self.authService = authService
        self.deviceId = Self.getOrCreateDeviceId()

        // Observe auth state
        authService.observeAuthState { [weak self] user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    // MARK: - Authentication Actions

    func signIn() async {
        guard validateForm() else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signIn(email: email, password: password)
            try await authService.registerDevice(deviceId: deviceId)
            clearForm()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "予期せぬエラーが発生しました"
        }

        isLoading = false
    }

    func signUp() async {
        guard validateForm() else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName.isEmpty ? nil : displayName
            )
            try await authService.registerDevice(deviceId: deviceId)
            clearForm()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "予期せぬエラーが発生しました"
        }

        isLoading = false
    }

    func signOut() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.unregisterDevice(deviceId: deviceId)
            try await authService.signOut()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "予期せぬエラーが発生しました"
        }

        isLoading = false
    }

    func sendPasswordReset() async {
        guard !email.isEmpty else {
            emailError = "メールアドレスを入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.sendPasswordResetEmail(to: email)
            errorMessage = "パスワードリセットメールを送信しました"
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "予期せぬエラーが発生しました"
        }

        isLoading = false
    }

    // MARK: - Form Actions

    func toggleAuthMode() {
        isSignUpMode.toggle()
        clearErrors()
    }

    func clearForm() {
        email = ""
        password = ""
        displayName = ""
        clearErrors()
    }

    func clearErrors() {
        emailError = nil
        passwordError = nil
        errorMessage = nil
    }

    // MARK: - Validation

    private func validateForm() -> Bool {
        clearErrors()
        var isValid = true

        // Email validation
        if email.isEmpty {
            emailError = "メールアドレスを入力してください"
            isValid = false
        } else if !isValidEmail(email) {
            emailError = "有効なメールアドレスを入力してください"
            isValid = false
        }

        // Password validation
        if password.isEmpty {
            passwordError = "パスワードを入力してください"
            isValid = false
        } else if password.count < 6 {
            passwordError = "パスワードは6文字以上で入力してください"
            isValid = false
        }

        return isValid
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // MARK: - Device ID

    private static func getOrCreateDeviceId() -> String {
        let key = "AsaExpenseSync.deviceId"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    var currentDeviceId: String {
        deviceId
    }
}
