import CoreLocation
import Foundation

// MARK: - ジオフェンス監視プロトコル

/// ジオフェンス監視のインターフェース（テスト用モック注入可能）
public protocol GeofenceMonitoring: Sendable {
    /// ジオフェンス監視を開始
    func startMonitoring(
        identifier: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double
    ) async throws

    /// ジオフェンス監視を停止
    func stopMonitoring(identifier: String) async

    /// 全ジオフェンス監視を停止
    func stopAllMonitoring() async

    /// 現在監視中のリージョン数
    var monitoredRegionCount: Int { get async }
}
