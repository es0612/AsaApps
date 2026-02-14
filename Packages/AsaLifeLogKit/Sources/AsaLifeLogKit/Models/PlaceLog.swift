import Foundation
import SwiftData

// MARK: - PlaceLog

/// 訪問場所ログ
///
/// ユーザーがよく訪れる場所を記録し、訪問頻度や最終訪問日を管理する。
@Model
public final class PlaceLog {
    @Attribute(.unique) public var id: UUID = UUID()
    public var name: String = ""
    public var latitude: Double = 0.0
    public var longitude: Double = 0.0
    public var address: String?
    public var categoryRawValue: String = PlaceCategory.other.rawValue
    public var visitCount: Int = 0
    public var firstVisitedAt: Date = Date()
    public var lastVisitedAt: Date = Date()
    public var isFavorite: Bool = false

    // MARK: - Computed Properties

    /// 場所カテゴリ
    public var category: PlaceCategory {
        get { PlaceCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    // MARK: - Init

    public init(
        name: String = "",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        address: String? = nil,
        category: PlaceCategory = .other,
        visitCount: Int = 0,
        firstVisitedAt: Date = Date(),
        lastVisitedAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.categoryRawValue = category.rawValue
        self.visitCount = visitCount
        self.firstVisitedAt = firstVisitedAt
        self.lastVisitedAt = lastVisitedAt
        self.isFavorite = isFavorite
    }
}
