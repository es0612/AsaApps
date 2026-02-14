import Foundation
import SwiftData

// MARK: - LocalBusiness

/// 地域のお店モデル
@Model
public final class LocalBusiness {
    public var id: UUID = UUID()
    public var name: String = ""
    public var businessDescription: String = ""
    public var categoryRawValue: String = BusinessCategory.other.rawValue
    public var address: String = ""
    public var latitude: Double = 0.0
    public var longitude: Double = 0.0
    public var phoneNumber: String = ""
    public var businessHours: String = ""
    public var closedDays: String = ""
    public var imageData: Data?
    public var isFavorite: Bool = false
    public var rating: Double = 0.0
    public var createdAt: Date = Date()

    public init(
        name: String,
        businessDescription: String = "",
        category: BusinessCategory = .other,
        address: String,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        phoneNumber: String = "",
        businessHours: String = "",
        closedDays: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.businessDescription = businessDescription
        self.categoryRawValue = category.rawValue
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.phoneNumber = phoneNumber
        self.businessHours = businessHours
        self.closedDays = closedDays
        self.createdAt = Date()
    }

    // MARK: - Category Accessor

    /// BusinessCategory への変換アクセサ
    public var category: BusinessCategory {
        get { BusinessCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}
