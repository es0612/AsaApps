//
//  SearchFilter.swift
//  AsaParkingFinder
//  
//  駐車場検索フィルター設定
//

import Foundation
import CoreLocation

// MARK: - SearchFilter

@Observable
final class SearchFilter {
    
    // MARK: - Properties
    
    var searchRadius: CLLocationDistance = 1000.0    // 検索範囲（m）
    var maxHourlyRate: Int?                          // 最大時間料金
    var maxDailyRate: Int?                           // 最大日料金
    var requiredAmenities: Set<ParkingAmenity> = []  // 必要な設備
    var paymentMethods: Set<PaymentMethod> = []      // 支払い方法
    var vehicleHeight: Double?                       // 車両高さ（cm）
    var vehicleWidth: Double?                        // 車両幅（cm）
    var vehicleLength: Double?                       // 車両長さ（cm）
    var vehicleWeight: Double?                       // 車両重量（kg）
    var sortBy: SortOption = .distance               // ソート方式
    var showOnlyAvailable: Bool = false              // 空きありのみ表示
    
    // MARK: - Computed Properties
    
    var hasActiveFilters: Bool {
        return maxHourlyRate != nil ||
               maxDailyRate != nil ||
               !requiredAmenities.isEmpty ||
               !paymentMethods.isEmpty ||
               hasVehicleRestrictions ||
               showOnlyAvailable
    }
    
    var hasVehicleRestrictions: Bool {
        return vehicleHeight != nil || vehicleWidth != nil || 
               vehicleLength != nil || vehicleWeight != nil
    }
    
    // MARK: - Methods
    
    func clearAllFilters() {
        maxHourlyRate = nil
        maxDailyRate = nil
        requiredAmenities.removeAll()
        paymentMethods.removeAll()
        vehicleHeight = nil
        vehicleWidth = nil
        vehicleLength = nil
        vehicleWeight = nil
        showOnlyAvailable = false
    }
    
    func clearVehicleRestrictions() {
        vehicleHeight = nil
        vehicleWidth = nil
        vehicleLength = nil
        vehicleWeight = nil
    }
    
    func matches(_ parkingLot: ParkingLot) -> Bool {
        // 料金フィルター
        if let maxHourly = maxHourlyRate,
           let hourlyRate = parkingLot.hourlyRate,
           hourlyRate > maxHourly {
            return false
        }
        
        if let maxDaily = maxDailyRate,
           let dailyRate = parkingLot.maxDailyRate,
           dailyRate > maxDaily {
            return false
        }
        
        // 設備フィルター
        if !requiredAmenities.isEmpty {
            let parkingAmenities = Set(parkingLot.amenities)
            if !requiredAmenities.isSubset(of: parkingAmenities) {
                return false
            }
        }
        
        // 支払い方法フィルター
        if !paymentMethods.isEmpty {
            let parkingPayments = Set(parkingLot.paymentMethods)
            if paymentMethods.intersection(parkingPayments).isEmpty {
                return false
            }
        }
        
        // 車両制限フィルター
        if hasVehicleRestrictions,
           let restrictions = parkingLot.vehicleRestrictions {
            if !restrictions.canAccommodate(
                height: vehicleHeight,
                width: vehicleWidth,
                length: vehicleLength,
                weight: vehicleWeight
            ) {
                return false
            }
        }
        
        // 空き状況フィルター
        if showOnlyAvailable && !parkingLot.isAvailable {
            return false
        }
        
        return true
    }
}

// MARK: - SortOption

enum SortOption: String, CaseIterable, Identifiable {
    case distance = "距離順"
    case hourlyRate = "時間料金順"
    case dailyRate = "日料金順"
    case availability = "空き率順"
    case name = "名前順"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .distance: return "location"
        case .hourlyRate: return "clock"
        case .dailyRate: return "calendar"
        case .availability: return "car.2"
        case .name: return "textformat.abc"
        }
    }
    
    func sort(_ parkingLots: [ParkingLot], userLocation: CLLocation?) -> [ParkingLot] {
        switch self {
        case .distance:
            guard let userLocation = userLocation else { return parkingLots }
            return parkingLots.sorted { lot1, lot2 in
                let distance1 = userLocation.distance(from: CLLocation(latitude: lot1.coordinate.latitude, longitude: lot1.coordinate.longitude))
                let distance2 = userLocation.distance(from: CLLocation(latitude: lot2.coordinate.latitude, longitude: lot2.coordinate.longitude))
                return distance1 < distance2
            }
        case .hourlyRate:
            return parkingLots.sorted { lot1, lot2 in
                guard let rate1 = lot1.hourlyRate, let rate2 = lot2.hourlyRate else {
                    return lot1.hourlyRate != nil
                }
                return rate1 < rate2
            }
        case .dailyRate:
            return parkingLots.sorted { lot1, lot2 in
                guard let rate1 = lot1.maxDailyRate, let rate2 = lot2.maxDailyRate else {
                    return lot1.maxDailyRate != nil
                }
                return rate1 < rate2
            }
        case .availability:
            return parkingLots.sorted { lot1, lot2 in
                return lot1.occupancyRate < lot2.occupancyRate
            }
        case .name:
            return parkingLots.sorted { $0.name < $1.name }
        }
    }
}

// MARK: - SearchRadius

enum SearchRadius: CLLocationDistance, CaseIterable, Identifiable {
    case radius500 = 500.0
    case radius1000 = 1000.0
    case radius2000 = 2000.0
    case radius5000 = 5000.0
    
    var id: CLLocationDistance { rawValue }
    
    var displayName: String {
        let km = rawValue / 1000.0
        if km < 1.0 {
            return "\(Int(rawValue))m"
        } else {
            return String(format: "%.1fkm", km)
        }
    }
    
    static var `default`: SearchRadius { .radius1000 }
}