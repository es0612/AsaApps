import Foundation
import SwiftUI
#if FIREBASE_ENABLED
import FirebaseAuth
import AuthenticationServices
#endif

// MARK: - User

struct AppUser: Identifiable, Codable, Sendable {
    var id: String
    var displayName: String
    var email: String?
    var photoURL: String?
    var createdAt: Date?

    init(
        id: String,
        displayName: String,
        email: String? = nil,
        photoURL: String? = nil,
        createdAt: Date? = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.createdAt = createdAt
    }

    static let demo = AppUser(
        id: "user-1",
        displayName: "山田パパ",
        email: "yamada@example.com"
    )
}

// MARK: - AuthState

enum AuthState: Sendable {
    case loading
    case signedOut
    case signedIn(AppUser)

    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }

    var user: AppUser? {
        if case .signedIn(let user) = self { return user }
        return nil
    }
}

// MARK: - AuthViewModel

@Observable
@MainActor
final class AuthViewModel {
    // MARK: - Properties

    private(set) var state: AuthState = .loading
    private(set) var errorMessage: String?
    private(set) var isProcessing: Bool = false

    let dataService: any EventDataServiceProtocol

    #if FIREBASE_ENABLED
    private var authStateListener: AuthStateDidChangeListenerHandle?
    #endif

    // MARK: - Computed Properties

    var currentUser: AppUser? {
        state.user
    }

    var isSignedIn: Bool {
        state.isSignedIn
    }

    // MARK: - Initialization

    init(dataService: any EventDataServiceProtocol) {
        self.dataService = dataService
        setupAuthStateListener()
    }

    // Note: リスナーはアプリのライフサイクル全体で維持されるため、deinitでの解除は不要

    // MARK: - Private Methods

    private func setupAuthStateListener() {
        #if FIREBASE_ENABLED
        // Firestoreサービスを使用している場合のみFirebase Authを有効化
        if dataService is FirestoreEventDataService {
            authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    if let user = user {
                        let appUser = AppUser(
                            id: user.uid,
                            displayName: user.displayName ?? "ユーザー",
                            email: user.email,
                            photoURL: user.photoURL?.absoluteString
                        )
                        self.state = .signedIn(appUser)
                    } else {
                        self.state = .signedOut
                    }
                }
            }
        } else {
            // Mockサービスの場合はデモモードでサインイン
            state = .signedIn(AppUser.demo)
        }
        #else
        // Firebaseが無効の場合は自動的にデモモードでサインイン
        state = .signedIn(AppUser.demo)
        #endif
    }

    // MARK: - Public Methods

    func signInWithApple(credential: Any) async {
        #if FIREBASE_ENABLED
        // Firestoreサービスを使用している場合のみFirebase Authで認証
        guard dataService is FirestoreEventDataService else {
            state = .signedIn(AppUser.demo)
            return
        }

        guard let appleCredential = credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Apple認証に失敗しました"
            return
        }

        guard let identityToken = appleCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            errorMessage = "認証トークンの取得に失敗しました"
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            let credential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: nil,
                fullName: appleCredential.fullName
            )
            let result = try await Auth.auth().signIn(with: credential)

            // 初回サインイン時に表示名を更新
            if let fullName = appleCredential.fullName,
               let givenName = fullName.givenName {
                let displayName = [givenName, fullName.familyName].compactMap { $0 }.joined(separator: " ")
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }

            isProcessing = false
        } catch {
            isProcessing = false
            errorMessage = "サインインに失敗しました: \(error.localizedDescription)"
        }
        #else
        state = .signedIn(AppUser.demo)
        #endif
    }

    func signInAsDemo() {
        state = .signedIn(AppUser.demo)
    }

    func signOut() {
        #if FIREBASE_ENABLED
        // Firestoreサービスを使用している場合のみFirebase Authでサインアウト
        if dataService is FirestoreEventDataService {
            do {
                try Auth.auth().signOut()
            } catch {
                errorMessage = "サインアウトに失敗しました: \(error.localizedDescription)"
            }
        } else {
            state = .signedOut
        }
        #else
        state = .signedOut
        #endif
    }

    func clearError() {
        errorMessage = nil
    }
}
