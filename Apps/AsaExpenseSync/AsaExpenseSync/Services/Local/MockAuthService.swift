import Foundation

// MARK: - MockAuthService

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    // MARK: - Properties

    private(set) var isAuthenticated: Bool = false
    private(set) var currentUser: UserProfile?

    private var users: [String: (profile: UserProfile, password: String)] = [:]
    private var authStateHandler: ((UserProfile?) -> Void)?

    // MARK: - Initialization

    init() {
        // Pre-populate with a demo user
        let demoUser = UserProfile(
            id: "demo-user-id",
            email: "demo@example.com",
            displayName: "デモユーザー",
            createdAt: Date(),
            deviceIds: []
        )
        users["demo@example.com"] = (demoUser, "password123")
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay

        guard let user = users[email.lowercased()] else {
            throw AuthError.userNotFound
        }

        guard user.password == password else {
            throw AuthError.invalidCredentials
        }

        var profile = user.profile
        profile.lastSignInAt = Date()

        isAuthenticated = true
        currentUser = profile
        authStateHandler?(profile)

        print("MockAuthService: User signed in - \(email)")
    }

    func signUp(email: String, password: String, displayName: String?) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay

        let normalizedEmail = email.lowercased()

        guard users[normalizedEmail] == nil else {
            throw AuthError.emailAlreadyInUse
        }

        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }

        let profile = UserProfile(
            id: UUID().uuidString,
            email: normalizedEmail,
            displayName: displayName,
            createdAt: Date(),
            lastSignInAt: Date(),
            deviceIds: []
        )

        users[normalizedEmail] = (profile, password)

        isAuthenticated = true
        currentUser = profile
        authStateHandler?(profile)

        print("MockAuthService: User signed up - \(email)")
    }

    func signOut() async throws {
        try await Task.sleep(nanoseconds: 200_000_000) // Simulate network delay

        isAuthenticated = false
        currentUser = nil
        authStateHandler?(nil)

        print("MockAuthService: User signed out")
    }

    // MARK: - User Profile

    func fetchUserProfile() async throws -> UserProfile? {
        try await Task.sleep(nanoseconds: 300_000_000)
        return currentUser
    }

    func updateUserProfile(displayName: String?, photoURL: String?) async throws {
        guard var user = currentUser else {
            throw AuthError.userNotFound
        }

        if let displayName = displayName {
            user.displayName = displayName
        }
        if let photoURL = photoURL {
            user.photoURL = photoURL
        }

        currentUser = user
        if let email = currentUser?.email.lowercased() {
            if var stored = users[email] {
                stored.profile = user
                users[email] = stored
            }
        }

        authStateHandler?(user)
    }

    // MARK: - Device Management

    func registerDevice(deviceId: String) async throws {
        guard var user = currentUser else {
            throw AuthError.userNotFound
        }

        if !user.deviceIds.contains(deviceId) {
            user.deviceIds.append(deviceId)
            currentUser = user
        }
    }

    func unregisterDevice(deviceId: String) async throws {
        guard var user = currentUser else {
            throw AuthError.userNotFound
        }

        user.deviceIds.removeAll { $0 == deviceId }
        currentUser = user
    }

    // MARK: - Password

    func sendPasswordResetEmail(to email: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)

        guard users[email.lowercased()] != nil else {
            throw AuthError.userNotFound
        }

        print("MockAuthService: Password reset email sent to \(email)")
    }

    // MARK: - Observation

    func observeAuthState(_ handler: @escaping (UserProfile?) -> Void) {
        self.authStateHandler = handler
        handler(currentUser)
    }
}
