import Foundation
import AuthenticationServices
#if FIREBASE_ENABLED
import FirebaseAuth
import FirebaseFirestore
#endif

// MARK: - Firebase Auth Service

#if FIREBASE_ENABLED
final class FirebaseAuthService: AuthService, @unchecked Sendable {
    // MARK: - Properties

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private(set) var currentUser: User?

    var isAuthenticated: Bool {
        auth.currentUser != nil
    }

    // MARK: - Initializer

    init() {
        // 初期ユーザー状態を設定
        if let firebaseUser = auth.currentUser {
            Task {
                await loadUserProfile(uid: firebaseUser.uid)
            }
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple(authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        guard let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nil,
            fullName: appleIDCredential.fullName
        )

        do {
            let result = try await auth.signIn(with: credential)
            let firebaseUser = result.user

            // 新規ユーザーの場合はプロファイルを作成
            let displayName = appleIDCredential.fullName?.formatted() ?? firebaseUser.displayName ?? ""

            let user = User(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                displayName: displayName,
                photoURL: firebaseUser.photoURL?.absoluteString,
                createdAt: Date(),
                updatedAt: Date()
            )

            try await saveUserProfile(user)
            self.currentUser = user
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        do {
            try auth.signOut()
            currentUser = nil
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }

    // MARK: - Update Profile

    func updateUserProfile(displayName: String?, photoURL: String?) async throws {
        guard let uid = auth.currentUser?.uid else {
            throw AuthError.userNotFound
        }

        var updates: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]

        if let displayName = displayName {
            updates["displayName"] = displayName
        }

        if let photoURL = photoURL {
            updates["photoURL"] = photoURL
        }

        do {
            try await db.collection("users").document(uid).updateData(updates)
            await loadUserProfile(uid: uid)
        } catch {
            throw AuthError.unknown(error)
        }
    }

    // MARK: - Update FCM Token

    func updateFCMToken(_ token: String) async throws {
        guard let uid = auth.currentUser?.uid else { return }

        do {
            try await db.collection("users").document(uid).updateData([
                "fcmToken": token,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            // FCMトークン更新失敗は致命的ではないのでログのみ
            print("FCM token update failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Auth State Listener

    func addAuthStateListener(_ handler: @escaping (User?) -> Void) -> Any {
        return auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                Task {
                    await self?.loadUserProfile(uid: firebaseUser.uid)
                    handler(self?.currentUser)
                }
            } else {
                self?.currentUser = nil
                handler(nil)
            }
        }
    }

    // MARK: - Private Methods

    private func loadUserProfile(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if document.exists {
                currentUser = try document.data(as: User.self)
            }
        } catch {
            print("Failed to load user profile: \(error.localizedDescription)")
        }
    }

    private func saveUserProfile(_ user: User) async throws {
        guard let uid = user.id else { return }

        let documentRef = db.collection("users").document(uid)
        let document = try await documentRef.getDocument()

        if document.exists {
            // 既存ユーザー: updatedAtのみ更新
            try await documentRef.updateData([
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } else {
            // 新規ユーザー: 全フィールドを保存
            try documentRef.setData(from: user)
        }
    }
}

#else

// MARK: - Mock Auth Service (Non-Firebase)

final class FirebaseAuthService: AuthService, @unchecked Sendable {
    private(set) var currentUser: User?

    var isAuthenticated: Bool { currentUser != nil }

    func signInWithApple(authorization: ASAuthorization) async throws {
        // ローカルモックユーザー
        currentUser = User(
            id: UUID().uuidString,
            email: "mock@example.com",
            displayName: "Mock User",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func signOut() throws {
        currentUser = nil
    }

    func updateUserProfile(displayName: String?, photoURL: String?) async throws {
        // No-op in mock mode
    }

    func updateFCMToken(_ token: String) async throws {
        // No-op in mock mode
    }

    func addAuthStateListener(_ handler: @escaping (User?) -> Void) -> Any {
        handler(currentUser)
        return NSObject()
    }
}
#endif
