import Foundation
import LocalAuthentication

// MARK: - BiometricType

/// 生体認証の種類
public enum BiometricType: Sendable {
    case faceID
    case touchID
    case none
}

// MARK: - BiometricAuthService

/// Face ID / Touch ID 認証サービス
public final class BiometricAuthService: Sendable {
    public init() {}

    // MARK: - Methods

    /// Face ID / Touch IDで認証を実行
    /// - Returns: 認証成功ならtrue
    /// - Throws: 認証失敗時に `FinancePlannerError.authenticationFailed`
    public func authenticate() async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            throw FinancePlannerError.authenticationFailed
        }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "資産データを保護するために認証が必要です"
        )
    }

    /// 生体認証が利用可能かチェック
    /// - Returns: 利用可能ならtrue
    public func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }

    /// 認証タイプを取得（Face ID / Touch ID / なし）
    /// - Returns: 利用可能な認証タイプ
    public func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .none, .opticID:
            return .none
        @unknown default:
            return .none
        }
    }
}
