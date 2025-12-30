import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class FirebaseAuthService: AuthService {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: UserProfile?

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateHandler: ((Bool, UserProfile?) -> Void)?
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    // MARK: - AuthService Protocol Implementation

    func observeAuthState(handler: @escaping (Bool, UserProfile?) -> Void) {
        self.authStateHandler = handler
        // 初回呼び出し
        handler(isAuthenticated, currentUser)
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            // Firestoreにユーザープロファイル保存
            let profile = UserProfile(
                uid: result.user.uid,
                email: email,
                displayName: displayName,
                createdAt: Date(),
                updatedAt: Date()
            )

            try await db.collection("users").document(result.user.uid).setData(from: profile)

            // 状態更新（リスナーが自動処理）
        } catch {
            throw mapAuthError(error)
        }
    }

    func signIn(email: String, password: String) async throws {
        do {
            _ = try await auth.signIn(withEmail: email, password: password)
            // 状態更新（リスナーが自動処理）
        } catch {
            throw mapAuthError(error)
        }
    }

    func signOut() throws {
        do {
            try auth.signOut()
            // 状態更新（リスナーが自動処理）
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw mapAuthError(error)
        }
    }

    func updateUserFamilyId(_ familyId: String) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        do {
            try await db.collection("users").document(userId).updateData([
                "familyId": familyId,
                "updatedAt": FieldValue.serverTimestamp()
            ])

            // ローカル状態更新
            if var profile = currentUser {
                profile.familyId = familyId
                profile.updatedAt = Date()
                currentUser = profile
                authStateHandler?(true, profile)
            }
        } catch {
            throw AuthError.updateFailed(error.localizedDescription)
        }
    }

    // MARK: - Private Methods

    private func setupAuthStateListener() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let user = user {
                    // Firestoreからプロファイル取得
                    do {
                        let profile = try await self.fetchUserProfile(userId: user.uid)
                        self.isAuthenticated = true
                        self.currentUser = profile
                        self.authStateHandler?(true, profile)
                    } catch {
                        print("⚠️ プロファイル取得エラー: \(error)")
                        self.isAuthenticated = false
                        self.currentUser = nil
                        self.authStateHandler?(false, nil)
                    }
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.authStateHandler?(false, nil)
                }
            }
        }
    }

    private func fetchUserProfile(userId: String) async throws -> UserProfile {
        let document = try await db.collection("users").document(userId).getDocument()

        guard let profile = try? document.data(as: UserProfile.self) else {
            throw AuthError.invalidCredentials
        }

        return profile
    }

    private func mapAuthError(_ error: Error) -> AuthError {
        let nsError = error as NSError

        if nsError.domain == AuthErrorDomain,
           let authError = AuthErrorCode(_bridgedNSError: nsError) {
            switch authError.code {
            case .emailAlreadyInUse:
                return .emailAlreadyInUse
            case .invalidEmail:
                return .invalidEmail
            case .weakPassword:
                return .weakPassword
            case .wrongPassword, .userNotFound:
                return .invalidCredentials
            case .networkError:
                return .networkError
            default:
                return .unknown(error.localizedDescription)
            }
        }

        return .unknown(error.localizedDescription)
    }
}
