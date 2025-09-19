import Foundation
import FirebaseAuth
import FirebaseFirestore
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

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        checkAuthState()
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func checkAuthState() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.isAuthenticated = true
                    await self?.fetchUserProfile(uid: user.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }
        }
    }

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            let userProfile = UserProfile(
                uid: result.user.uid,
                email: email,
                displayName: displayName,
                createdAt: Date(),
                updatedAt: Date()
            )

            try await saveUserProfile(userProfile)
            currentUser = userProfile
            isAuthenticated = true
        } catch {
            errorMessage = handleAuthError(error)
        }

        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await fetchUserProfile(uid: result.user.uid)
            isAuthenticated = true
        } catch {
            errorMessage = handleAuthError(error)
        }

        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
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
            try await Auth.auth().sendPasswordReset(withEmail: email)
            errorMessage = "パスワードリセットメールを送信しました"
        } catch {
            errorMessage = handleAuthError(error)
        }

        isLoading = false
    }

    private func fetchUserProfile(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if document.exists {
                currentUser = try document.data(as: UserProfile.self)
            }
        } catch {
            print("ユーザープロファイルの取得に失敗: \(error)")
        }
    }

    private func saveUserProfile(_ profile: UserProfile) async throws {
        try db.collection("users").document(profile.uid).setData(from: profile)
    }

    func updateUserFamilyId(_ familyId: String) async {
        guard var user = currentUser else { return }
        user.familyId = familyId
        if !user.familyIds.contains(familyId) {
            user.familyIds.append(familyId)
        }
        user.updatedAt = Date()

        do {
            try await saveUserProfile(user)
            currentUser = user
        } catch {
            errorMessage = "家族IDの更新に失敗しました: \(error.localizedDescription)"
        }
    }

    private func handleAuthError(_ error: Error) -> String {
        if let authError = error as NSError? {
            switch authError.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return "このメールアドレスは既に使用されています"
            case AuthErrorCode.invalidEmail.rawValue:
                return "無効なメールアドレスです"
            case AuthErrorCode.weakPassword.rawValue:
                return "パスワードは6文字以上で設定してください"
            case AuthErrorCode.wrongPassword.rawValue:
                return "パスワードが正しくありません"
            case AuthErrorCode.userNotFound.rawValue:
                return "ユーザーが見つかりません"
            case AuthErrorCode.networkError.rawValue:
                return "ネットワークエラーが発生しました"
            default:
                return "認証エラー: \(error.localizedDescription)"
            }
        }
        return error.localizedDescription
    }
}