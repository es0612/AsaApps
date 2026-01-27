import Foundation
#if FIREBASE_ENABLED
import FirebaseAuth
@preconcurrency import FirebaseFirestore
#endif

// MARK: - FirebaseExpenseAuthService

#if FIREBASE_ENABLED
@MainActor
final class FirebaseExpenseAuthService: AuthServiceProtocol, @unchecked Sendable {
    // MARK: - Properties

    private(set) var isAuthenticated: Bool = false
    private(set) var currentUser: UserProfile?

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var authStateHandler: ((UserProfile?) -> Void)?

    // MARK: - Initialization

    init() {
        setupAuthStateListener()
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.isAuthenticated = true
                    await self?.fetchAndSetUserProfile(userId: user.uid, email: user.email ?? "")
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                    self?.authStateHandler?(nil)
                }
            }
        }
    }

    private func fetchAndSetUserProfile(userId: String, email: String) async {
        do {
            let docRef = db.collection("users").document(userId)
            let document = try await docRef.getDocument()

            if document.exists, let profile = try? document.data(as: UserProfile.self) {
                currentUser = profile
                authStateHandler?(profile)
            } else {
                // Create new profile if doesn't exist
                let newProfile = UserProfile(
                    id: userId,
                    email: email,
                    createdAt: Date(),
                    lastSignInAt: Date(),
                    deviceIds: []
                )
                try docRef.setData(from: newProfile)
                currentUser = newProfile
                authStateHandler?(newProfile)
            }
        } catch {
            print("FirebaseExpenseAuthService: Error fetching user profile - \(error)")
            // Create basic profile from auth data
            let basicProfile = UserProfile(
                id: userId,
                email: email,
                createdAt: Date()
            )
            currentUser = basicProfile
            authStateHandler?(basicProfile)
        }
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)

            // Update last sign in
            try await db.collection("users").document(result.user.uid).updateData([
                "lastSignInAt": FieldValue.serverTimestamp()
            ])

            print("FirebaseExpenseAuthService: User signed in - \(email)")
        } catch let error as NSError {
            throw mapFirebaseAuthError(error)
        }
    }

    func signUp(email: String, password: String, displayName: String?) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            // Create user profile in Firestore
            let profile = UserProfile(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                createdAt: Date(),
                lastSignInAt: Date(),
                deviceIds: []
            )

            try db.collection("users").document(result.user.uid).setData(from: profile)

            // Update display name in Auth
            if let displayName = displayName {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }

            print("FirebaseExpenseAuthService: User signed up - \(email)")
        } catch let error as NSError {
            throw mapFirebaseAuthError(error)
        }
    }

    func signOut() async throws {
        do {
            try auth.signOut()
            print("FirebaseExpenseAuthService: User signed out")
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }

    // MARK: - User Profile

    func fetchUserProfile() async throws -> UserProfile? {
        guard let userId = auth.currentUser?.uid else {
            return nil
        }

        let document = try await db.collection("users").document(userId).getDocument()
        return try? document.data(as: UserProfile.self)
    }

    func updateUserProfile(displayName: String?, photoURL: String?) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.userNotFound
        }

        var updates: [String: Any] = [:]

        if let displayName = displayName {
            updates["displayName"] = displayName

            // Also update Auth profile
            let changeRequest = auth.currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = displayName
            try await changeRequest?.commitChanges()
        }

        if let photoURL = photoURL {
            updates["photoURL"] = photoURL
        }

        if !updates.isEmpty {
            try await db.collection("users").document(userId).updateData(updates)

            // Update local profile
            if var profile = currentUser {
                if let displayName = displayName {
                    profile.displayName = displayName
                }
                if let photoURL = photoURL {
                    profile.photoURL = photoURL
                }
                currentUser = profile
                authStateHandler?(profile)
            }
        }
    }

    // MARK: - Device Management

    func registerDevice(deviceId: String) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.userNotFound
        }

        try await db.collection("users").document(userId).updateData([
            "deviceIds": FieldValue.arrayUnion([deviceId])
        ])

        if var profile = currentUser, !profile.deviceIds.contains(deviceId) {
            profile.deviceIds.append(deviceId)
            currentUser = profile
        }

        print("FirebaseExpenseAuthService: Device registered - \(deviceId)")
    }

    func unregisterDevice(deviceId: String) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.userNotFound
        }

        try await db.collection("users").document(userId).updateData([
            "deviceIds": FieldValue.arrayRemove([deviceId])
        ])

        if var profile = currentUser {
            profile.deviceIds.removeAll { $0 == deviceId }
            currentUser = profile
        }

        print("FirebaseExpenseAuthService: Device unregistered - \(deviceId)")
    }

    // MARK: - Password

    func sendPasswordResetEmail(to email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
            print("FirebaseExpenseAuthService: Password reset email sent to \(email)")
        } catch let error as NSError {
            throw mapFirebaseAuthError(error)
        }
    }

    // MARK: - Observation

    func observeAuthState(_ handler: @escaping (UserProfile?) -> Void) {
        self.authStateHandler = handler
        handler(currentUser)
    }

    // MARK: - Error Mapping

    private func mapFirebaseAuthError(_ error: NSError) -> AuthError {
        let errorCode = AuthErrorCode(rawValue: error.code)

        switch errorCode {
        case .userNotFound:
            return .userNotFound
        case .wrongPassword:
            return .invalidCredentials
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkError
        default:
            return .unknown(error)
        }
    }
}
#endif
