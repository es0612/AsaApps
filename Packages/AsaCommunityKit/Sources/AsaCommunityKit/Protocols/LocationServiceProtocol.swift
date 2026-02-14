import Foundation
import CoreLocation

// MARK: - LocationServiceProtocol

/// CoreLocation抽象化プロトコル
@MainActor
public protocol LocationServiceProtocol {
    /// 現在位置
    var currentLocation: CLLocation? { get }

    /// 位置情報の利用許可状態
    var authorizationStatus: CLAuthorizationStatus { get }

    /// 位置情報の利用許可をリクエスト
    func requestAuthorization()

    /// 位置情報の取得を開始
    func startUpdatingLocation()

    /// 位置情報の取得を停止
    func stopUpdatingLocation()

    /// 2地点間の距離（メートル）を計算
    func distance(from: CLLocation, to: CLLocation) -> CLLocationDistance

    /// 指定座標からの距離（メートル）
    func distanceFromCurrent(latitude: Double, longitude: Double) -> CLLocationDistance?
}
