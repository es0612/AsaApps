import CoreLocation
import Foundation
import SwiftData

// MARK: - 場所モデル

/// ジオフェンスを設定する場所を表すモデル
/// 1つの場所に複数のリマインダーを紐付け可能
@Model
public final class ReminderLocation {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var radius: Double
    public var address: String?
    public var categoryRawValue: String
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \LocationReminder.location)
    public var reminders: [LocationReminder] = []

    // MARK: - Computed Properties

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var category: LocationCategory {
        get { LocationCategory(rawValue: categoryRawValue) ?? .custom }
        set { categoryRawValue = newValue.rawValue }
    }

    public var activeReminderCount: Int {
        reminders.filter { $0.isActive && !$0.isCompleted }.count
    }

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        radius: Double = 100,
        address: String? = nil,
        category: LocationCategory = .custom,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.address = address
        self.categoryRawValue = category.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Methods

    /// 指定座標からの距離（メートル）を計算
    public func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let fromLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: fromLocation)
    }
}
