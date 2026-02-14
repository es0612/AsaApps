import Foundation

// MARK: - LocationTrackingServiceProtocol

/// 位置情報トラッキングプロトコル
///
/// CoreLocation のラッパーとして、位置情報の取得・ジオコーディングを提供する。
@MainActor
public protocol LocationTrackingServiceProtocol: Sendable {
    /// 現在位置（緯度・経度）
    var currentLocation: (latitude: Double, longitude: Double)? { get }

    /// 位置情報利用許可状態（CLAuthorizationStatus の rawValue）
    var authorizationStatus: Int { get }

    /// 位置情報利用許可をリクエストする
    func requestAuthorization() async

    /// 位置情報トラッキングを開始する
    func startTracking()

    /// 位置情報トラッキングを停止する
    func stopTracking()

    /// 逆ジオコーディング（座標 → 住所文字列）
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String
}
