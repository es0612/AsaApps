#if os(iOS)
import CoreLocation
import Foundation
import UserNotifications

// MARK: - 権限ステータス

/// 位置情報と通知の権限状態を統合管理
public struct PermissionStatus: Sendable {
    public let locationStatus: CLAuthorizationStatus
    public let notificationStatus: UNAuthorizationStatus

    public var isLocationAuthorized: Bool {
        locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse
    }

    public var isLocationAlways: Bool {
        locationStatus == .authorizedAlways
    }

    public var isNotificationAuthorized: Bool {
        notificationStatus == .authorized
    }

    public var isFullyAuthorized: Bool {
        isLocationAuthorized && isNotificationAuthorized
    }

    public var needsOnboarding: Bool {
        locationStatus == .notDetermined || notificationStatus == .notDetermined
    }

    public init(
        locationStatus: CLAuthorizationStatus = .notDetermined,
        notificationStatus: UNAuthorizationStatus = .notDetermined
    ) {
        self.locationStatus = locationStatus
        self.notificationStatus = notificationStatus
    }
}

// MARK: - 権限サービス

/// 位置情報と通知の権限リクエスト・状態確認を管理
@MainActor
@Observable
public final class PermissionService: NSObject, CLLocationManagerDelegate, Sendable {
    public private(set) var permissionStatus: PermissionStatus = PermissionStatus()

    private let locationManager: CLLocationManager
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    // MARK: - Init

    override public init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }

    // MARK: - 状態確認

    /// 現在の権限状態を取得
    public func checkCurrentStatus() async {
        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = PermissionStatus(
            locationStatus: locationManager.authorizationStatus,
            notificationStatus: notificationSettings.authorizationStatus
        )
    }

    // MARK: - 位置情報権限

    /// WhenInUse権限をリクエスト
    @discardableResult
    public func requestLocationWhenInUse() async -> CLAuthorizationStatus {
        if locationManager.authorizationStatus != .notDetermined {
            return locationManager.authorizationStatus
        }
        let status = await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
        await checkCurrentStatus()
        return status
    }

    /// Always権限をリクエスト（WhenInUse取得後に使用）
    @discardableResult
    public func requestLocationAlways() async -> CLAuthorizationStatus {
        if locationManager.authorizationStatus == .authorizedAlways {
            return .authorizedAlways
        }
        let status = await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            locationManager.requestAlwaysAuthorization()
        }
        await checkCurrentStatus()
        return status
    }

    // MARK: - 通知権限

    /// 通知権限をリクエスト
    @discardableResult
    public func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await checkCurrentStatus()
            return granted
        } catch {
            await checkCurrentStatus()
            return false
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated {
            authorizationContinuation?.resume(returning: status)
            authorizationContinuation = nil
        }
    }
}
#endif
