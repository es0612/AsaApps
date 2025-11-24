import Foundation
#if FIREBASE_ENABLED
import FirebaseAuth
import FirebaseFirestore
#endif
import Combine

struct UserProfile: Codable {
    let uid: String
    var email: String
    var displayName: String
    var familyId: String?
    var familyIds: [String] = []
    var photoURL: String?
    var createdAt: Date
    var updatedAt: Date
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService) {
        self.authService = authService
        setupAuthStateObserver()
    }

    // MARK: - Private Methods

    private func setupAuthStateObserver() {
        // AuthServiceの認証状態を監視
        authService.observeAuthState { [weak self] isAuth, user in
            Task { @MainActor in
                self?.isAuthenticated = isAuth
                self?.currentUser = user
            }
        }

        // 初期状態を設定
        isAuthenticated = authService.isAuthenticated
        currentUser = authService.currentUser
    }

    // MARK: - Public Methods

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.signUp(email: email, password: password, displayName: displayName)
            currentUser = authService.currentUser
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "登録に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.signIn(email: email, password: password)
            currentUser = authService.currentUser
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func signOut() {
        do {
            try authService.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = "サインアウトに失敗しました: \(error.localizedDescription)"
        }
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.resetPassword(email: email)
            errorMessage = "パスワードリセットメールを送信しました"
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "パスワードリセットに失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func updateUserFamilyId(_ familyId: String) async {
        guard currentUser != nil else { return }

        do {
            try await authService.updateUserFamilyId(familyId)
            currentUser = authService.currentUser
        } catch {
            errorMessage = "家族IDの更新に失敗しました: \(error.localizedDescription)"
        }
    }
}
