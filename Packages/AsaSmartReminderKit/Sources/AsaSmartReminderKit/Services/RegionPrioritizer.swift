import CoreLocation
import Foundation

// MARK: - リージョン優先度管理

/// iOS の20リージョン制限に対応する優先度管理ロジック
/// ユーザーの現在地から近い順にソートし、上位20件を監視対象とする
public struct RegionPrioritizer: Sendable {
    /// 最大同時監視リージョン数（iOSの制限）
    public static let maxRegionCount = 20

    public init() {}

    /// 優先度付きの場所リスト
    public struct PrioritizedLocation: Sendable {
        public let location: LocationInfo
        public let distance: CLLocationDistance
        public let isMonitored: Bool

        public init(location: LocationInfo, distance: CLLocationDistance, isMonitored: Bool) {
            self.location = location
            self.distance = distance
            self.isMonitored = isMonitored
        }
    }

    /// 場所情報（SwiftDataモデルから分離したデータ転送用）
    public struct LocationInfo: Sendable, Identifiable {
        public let id: UUID
        public let name: String
        public let coordinate: CLLocationCoordinate2D
        public let radius: Double
        public let activeReminderCount: Int

        public init(
            id: UUID,
            name: String,
            coordinate: CLLocationCoordinate2D,
            radius: Double,
            activeReminderCount: Int
        ) {
            self.id = id
            self.name = name
            self.coordinate = coordinate
            self.radius = radius
            self.activeReminderCount = activeReminderCount
        }
    }

    // MARK: - 優先度計算

    /// ユーザー位置から近い順にソートし、監視すべき場所を決定
    /// - Parameters:
    ///   - locations: 全てのアクティブな場所
    ///   - userCoordinate: ユーザーの現在位置
    ///   - maxCount: 最大監視数（デフォルト20）
    /// - Returns: 優先度付き場所リスト（距離順）
    public func prioritize(
        locations: [LocationInfo],
        userCoordinate: CLLocationCoordinate2D,
        maxCount: Int = RegionPrioritizer.maxRegionCount
    ) -> [PrioritizedLocation] {
        // アクティブなリマインダーを持つ場所のみ対象
        let activeLocations = locations.filter { $0.activeReminderCount > 0 }

        // 距離を計算してソート
        let withDistances = activeLocations.map { location -> (LocationInfo, CLLocationDistance) in
            let userLocation = CLLocation(
                latitude: userCoordinate.latitude,
                longitude: userCoordinate.longitude
            )
            let targetLocation = CLLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            return (location, userLocation.distance(from: targetLocation))
        }
        .sorted { $0.1 < $1.1 }

        // 上位maxCount件を監視対象にマーク
        return withDistances.enumerated().map { index, pair in
            PrioritizedLocation(
                location: pair.0,
                distance: pair.1,
                isMonitored: index < maxCount
            )
        }
    }

    /// 監視すべき場所のIDリストを返す
    public func monitoredLocationIDs(
        locations: [LocationInfo],
        userCoordinate: CLLocationCoordinate2D,
        maxCount: Int = RegionPrioritizer.maxRegionCount
    ) -> Set<UUID> {
        let prioritized = prioritize(
            locations: locations,
            userCoordinate: userCoordinate,
            maxCount: maxCount
        )
        let ids = prioritized.filter(\.isMonitored).map(\.location.id)
        return Set(ids)
    }

    /// 監視対象の変更差分を計算
    public func calculateDiff(
        currentlyMonitored: Set<UUID>,
        locations: [LocationInfo],
        userCoordinate: CLLocationCoordinate2D,
        maxCount: Int = RegionPrioritizer.maxRegionCount
    ) -> MonitoringDiff {
        let newMonitored = monitoredLocationIDs(
            locations: locations,
            userCoordinate: userCoordinate,
            maxCount: maxCount
        )
        let toAdd = newMonitored.subtracting(currentlyMonitored)
        let toRemove = currentlyMonitored.subtracting(newMonitored)
        return MonitoringDiff(toAdd: toAdd, toRemove: toRemove)
    }

    /// 監視対象の差分
    public struct MonitoringDiff: Sendable {
        /// 新しく監視を追加する場所ID
        public let toAdd: Set<UUID>
        /// 監視を解除する場所ID
        public let toRemove: Set<UUID>

        public var hasChanges: Bool {
            !toAdd.isEmpty || !toRemove.isEmpty
        }
    }
}
