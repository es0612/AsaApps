//
//  ParkingLot.swift
//  AsaParkingFinder
//  
//  駐車場データモデル
//

import Foundation
import CoreLocation

// MARK: - ParkingLot

struct ParkingLot: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let hourlyRate: Int?                    // 時間料金（円）
    let maxDailyRate: Int?                  // 最大料金（円）
    let operatingHours: String              // 営業時間
    let totalSpaces: Int?                   // 総駐車台数
    let availableSpaces: Int?               // 利用可能台数
    let vehicleRestrictions: VehicleRestrictions?  // 車両制限
    let amenities: [ParkingAmenity]         // 設備・サービス
    let paymentMethods: [PaymentMethod]     // 支払い方法
    let lastUpdated: Date                   // 最終更新時刻
    
    // 計算プロパティ
    var isAvailable: Bool {
        guard let available = availableSpaces else { return true }
        return available > 0
    }
    
    var occupancyRate: Double {
        guard let total = totalSpaces, let available = availableSpaces, total > 0 else { return 0.0 }
        return Double(total - available) / Double(total)
    }
    
    var displayRate: String {
        if let hourly = hourlyRate, let daily = maxDailyRate {
            return "¥\(hourly)/時間（最大¥\(daily)）"
        } else if let hourly = hourlyRate {
            return "¥\(hourly)/時間"
        } else if let daily = maxDailyRate {
            return "¥\(daily)/日"
        } else {
            return "料金不明"
        }
    }
}

// MARK: - VehicleRestrictions

struct VehicleRestrictions: Codable, Hashable {
    let maxHeight: Double?      // cm
    let maxWidth: Double?       // cm
    let maxLength: Double?      // cm
    let maxWeight: Double?      // kg
    
    func canAccommodate(height: Double?, width: Double?, length: Double?, weight: Double?) -> Bool {
        if let maxH = maxHeight, let h = height, h > maxH { return false }
        if let maxW = maxWidth, let w = width, w > maxW { return false }
        if let maxL = maxLength, let l = length, l > maxL { return false }
        if let maxWeight = maxWeight, let w = weight, w > maxWeight { return false }
        return true
    }
}

// MARK: - ParkingAmenity

enum ParkingAmenity: String, CaseIterable, Codable {
    case roofed = "屋根付き"
    case security = "セキュリティ"
    case evCharging = "EV充電"
    case washService = "洗車サービス"
    case toilet = "トイレ"
    case vendingMachine = "自販機"
    case barrier = "バリアフリー"
    case cctv = "防犯カメラ"
    
    var icon: String {
        switch self {
        case .roofed: return "building.2"
        case .security: return "lock.shield"
        case .evCharging: return "bolt.car"
        case .washService: return "car.wash"
        case .toilet: return "toilet"
        case .vendingMachine: return "button.programmable"
        case .barrier: return "accessibility"
        case .cctv: return "video"
        }
    }
}

// MARK: - PaymentMethod

enum PaymentMethod: String, CaseIterable, Codable {
    case cash = "現金"
    case creditCard = "クレジットカード"
    case ic = "ICカード"
    case qr = "QR決済"
    case app = "専用アプリ"
    
    var icon: String {
        switch self {
        case .cash: return "yensign.circle"
        case .creditCard: return "creditcard"
        case .ic: return "wave.3.right.circle"
        case .qr: return "qrcode"
        case .app: return "app.badge"
        }
    }
}

// MARK: - Codable Extensions for CLLocationCoordinate2D

extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}