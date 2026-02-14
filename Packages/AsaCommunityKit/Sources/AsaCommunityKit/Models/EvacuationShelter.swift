import Foundation
import SwiftData

// MARK: - EvacuationShelter

/// 避難所モデル
@Model
public final class EvacuationShelter {
    public var id: UUID = UUID()
    public var name: String = ""
    public var address: String = ""
    public var latitude: Double = 0.0
    public var longitude: Double = 0.0
    public var capacity: Int = 0
    public var currentOccupancy: Int = 0
    public var hasWater: Bool = false
    public var hasFood: Bool = false
    public var hasMedical: Bool = false
    public var hasElectricity: Bool = false
    public var phoneNumber: String = ""
    public var isOpen: Bool = false

    public init(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        capacity: Int,
        hasWater: Bool = false,
        hasFood: Bool = false,
        hasMedical: Bool = false,
        hasElectricity: Bool = false,
        phoneNumber: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.capacity = capacity
        self.hasWater = hasWater
        self.hasFood = hasFood
        self.hasMedical = hasMedical
        self.hasElectricity = hasElectricity
        self.phoneNumber = phoneNumber
    }

    // MARK: - Computed Properties

    /// 収容率（0.0〜1.0）
    public var occupancyRate: Double {
        guard capacity > 0 else { return 0.0 }
        return Double(currentOccupancy) / Double(capacity)
    }

    /// 残り収容可能人数
    public var remainingCapacity: Int {
        max(capacity - currentOccupancy, 0)
    }

    /// 設備一覧テキスト
    public var facilitiesText: String {
        var items: [String] = []
        if hasWater { items.append("給水") }
        if hasFood { items.append("食料") }
        if hasMedical { items.append("医療") }
        if hasElectricity { items.append("電源") }
        return items.isEmpty ? "情報なし" : items.joined(separator: "・")
    }
}
