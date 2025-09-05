//
//  MockParkingService.swift
//  AsaParkingFinder
//  
//  モックデータを使用した駐車場サービス実装
//  開発・デモ・テスト用
//

import Foundation
import CoreLocation

// MARK: - MockParkingService

final class MockParkingService: ParkingServiceProtocol {
    
    private let mockData: [ParkingLot]
    
    init() {
        self.mockData = Self.createMockData()
        print("🅿️ MockParkingService初期化完了: \(mockData.count)件の駐車場データ")
    }
    
    // MARK: - ParkingServiceProtocol Implementation
    
    func searchParking(
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        filter: SearchFilter?
    ) async throws -> [ParkingLot] {
        print("🅿️ 駐車場検索開始 - 中心: (\(center.latitude), \(center.longitude)), 半径: \(Int(radius))m")
        
        // 検索位置の妥当性チェック
        guard center.latitude != 0 && center.longitude != 0 else {
            throw ParkingServiceError.invalidCoordinates
        }
        
        // 検索結果をシミュレートするため少し待機
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        let userLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        // 範囲内の駐車場をフィルタリング
        let nearbyLots = mockData.filter { lot in
            let lotLocation = CLLocation(latitude: lot.coordinate.latitude, longitude: lot.coordinate.longitude)
            return userLocation.distance(from: lotLocation) <= radius
        }
        
        // フィルター適用
        var filteredLots = nearbyLots
        if let filter = filter {
            filteredLots = nearbyLots.filter { filter.matches($0) }
        }
        
        // ソート適用
        let sortedLots = filter?.sortBy.sort(filteredLots, userLocation: userLocation) ?? filteredLots
        
        print("🅿️ 検索結果: \(sortedLots.count)件の駐車場")
        return sortedLots
    }
    
    func getParkingDetail(id: String) async throws -> ParkingLot? {
        print("🅿️ 駐車場詳細取得: ID \(id)")
        
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        let lot = mockData.first { $0.id == id }
        
        if lot == nil {
            print("❌ 駐車場が見つかりません: ID \(id)")
            throw ParkingServiceError.noDataFound
        }
        
        return lot
    }
    
    func getFavoriteParkingLots(ids: [String]) async throws -> [ParkingLot] {
        print("🅿️ お気に入り駐車場取得: \(ids.count)件")
        
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
        
        return mockData.filter { ids.contains($0.id) }
    }
    
    func updateAvailability(id: String) async throws -> ParkingLot? {
        print("🅿️ 空き状況更新: ID \(id)")
        
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4秒
        
        guard var lot = mockData.first(where: { $0.id == id }) else {
            throw ParkingServiceError.noDataFound
        }
        
        // ランダムに空き状況を更新（デモ用）
        if let total = lot.totalSpaces {
            let newAvailable = Int.random(in: 0...total)
            lot = ParkingLot(
                id: lot.id,
                name: lot.name,
                coordinate: lot.coordinate,
                address: lot.address,
                hourlyRate: lot.hourlyRate,
                maxDailyRate: lot.maxDailyRate,
                operatingHours: lot.operatingHours,
                totalSpaces: lot.totalSpaces,
                availableSpaces: newAvailable,
                vehicleRestrictions: lot.vehicleRestrictions,
                amenities: lot.amenities,
                paymentMethods: lot.paymentMethods,
                lastUpdated: Date()
            )
        }
        
        return lot
    }
    
    // MARK: - Mock Data Generation
    
    private static func createMockData() -> [ParkingLot] {
        return [
            // 東京駅周辺
            ParkingLot(
                id: "tokyo-station-01",
                name: "東京駅八重洲パーキング",
                coordinate: CLLocationCoordinate2D(latitude: 35.6796, longitude: 139.7685),
                address: "東京都千代田区丸の内1-9",
                hourlyRate: 300,
                maxDailyRate: 2400,
                operatingHours: "24時間営業",
                totalSpaces: 150,
                availableSpaces: 23,
                vehicleRestrictions: VehicleRestrictions(maxHeight: 210, maxWidth: 190, maxLength: 500, maxWeight: 2000),
                amenities: [.roofed, .security, .evCharging, .toilet],
                paymentMethods: [.cash, .creditCard, .ic],
                lastUpdated: Date().addingTimeInterval(-300)
            ),
            
            ParkingLot(
                id: "marunouchi-02",
                name: "丸の内センタービルディング駐車場",
                coordinate: CLLocationCoordinate2D(latitude: 35.6837, longitude: 139.7632),
                address: "東京都千代田区丸の内1-6-1",
                hourlyRate: 400,
                maxDailyRate: 3200,
                operatingHours: "平日 7:00-23:00",
                totalSpaces: 200,
                availableSpaces: 45,
                vehicleRestrictions: VehicleRestrictions(maxHeight: 200, maxWidth: 185, maxLength: 485, maxWeight: 1800),
                amenities: [.roofed, .security, .washService, .vendingMachine],
                paymentMethods: [.creditCard, .ic, .qr],
                lastUpdated: Date().addingTimeInterval(-180)
            ),
            
            // 渋谷周辺
            ParkingLot(
                id: "shibuya-sky-03",
                name: "渋谷スカイパーキング",
                coordinate: CLLocationCoordinate2D(latitude: 35.6580, longitude: 139.7016),
                address: "東京都渋谷区道玄坂2-6-17",
                hourlyRate: 350,
                maxDailyRate: 2800,
                operatingHours: "24時間営業",
                totalSpaces: 120,
                availableSpaces: 8,
                vehicleRestrictions: VehicleRestrictions(maxHeight: 155, maxWidth: 175, maxLength: 470, maxWeight: 1600),
                amenities: [.security, .cctv, .barrier],
                paymentMethods: [.cash, .creditCard, .app],
                lastUpdated: Date().addingTimeInterval(-120)
            ),
            
            // 新宿周辺
            ParkingLot(
                id: "shinjuku-central-04",
                name: "新宿セントラルパーク駐車場",
                coordinate: CLLocationCoordinate2D(latitude: 35.6938, longitude: 139.6939),
                address: "東京都新宿区西新宿1-25-1",
                hourlyRate: 300,
                maxDailyRate: 2500,
                operatingHours: "6:00-24:00",
                totalSpaces: 300,
                availableSpaces: 67,
                vehicleRestrictions: VehicleRestrictions(maxHeight: 220, maxWidth: 200, maxLength: 520, maxWeight: 2200),
                amenities: [.roofed, .security, .evCharging, .toilet, .vendingMachine],
                paymentMethods: [.cash, .creditCard, .ic, .qr],
                lastUpdated: Date().addingTimeInterval(-90)
            ),
            
            // 銀座周辺
            ParkingLot(
                id: "ginza-core-05",
                name: "銀座コアビル駐車場",
                coordinate: CLLocationCoordinate2D(latitude: 35.6717, longitude: 139.7619),
                address: "東京都中央区銀座5-8-20",
                hourlyRate: 500,
                maxDailyRate: 4000,
                operatingHours: "10:00-21:00",
                totalSpaces: 80,
                availableSpaces: 12,
                vehicleRestrictions: VehicleRestrictions(maxHeight: 190, maxWidth: 180, maxLength: 480, maxWeight: 1700),
                amenities: [.roofed, .security, .barrier, .washService],
                paymentMethods: [.creditCard, .ic, .app],
                lastUpdated: Date().addingTimeInterval(-60)
            ),
            
            // お台場周辺
            ParkingLot(
                id: "odaiba-aqua-06",
                name: "アクアシティお台場駐車場",
                coordinate: CLLocationCoordinate2D(latitude: 35.6294, longitude: 139.7744),
                address: "東京都港区台場1-7-1",
                hourlyRate: 250,
                maxDailyRate: 2000,
                operatingHours: "24時間営業",
                totalSpaces: 900,
                availableSpaces: 234,
                vehicleRestrictions: VehicleRestrictions(maxHeight: 210, maxWidth: 190, maxLength: 500, maxWeight: 2000),
                amenities: [.roofed, .security, .evCharging, .toilet, .vendingMachine, .barrier],
                paymentMethods: [.cash, .creditCard, .ic, .qr, .app],
                lastUpdated: Date().addingTimeInterval(-45)
            ),
            
            // 上野周辺
            ParkingLot(
                id: "ueno-park-07",
                name: "上野パークセンター駐車場",
                coordinate: CLLocationCoordinate2D(latitude: 35.7141, longitude: 139.7750),
                address: "東京都台東区上野公園1-57",
                hourlyRate: 200,
                maxDailyRate: 1600,
                operatingHours: "9:00-20:00",
                totalSpaces: 100,
                availableSpaces: 28,
                vehicleRestrictions: VehicleRestrictions(maxHeight: 200, maxWidth: 185, maxLength: 485, maxWeight: 1800),
                amenities: [.security, .cctv, .toilet, .vendingMachine],
                paymentMethods: [.cash, .creditCard, .ic],
                lastUpdated: Date().addingTimeInterval(-30)
            ),
            
            // 池袋周辺
            ParkingLot(
                id: "ikebukuro-sunshine-08",
                name: "サンシャインシティ駐車場",
                coordinate: CLLocationCoordinate2D(latitude: 35.7295, longitude: 139.7188),
                address: "東京都豊島区東池袋3-1-1",
                hourlyRate: 300,
                maxDailyRate: 2400,
                operatingHours: "24時間営業",
                totalSpaces: 1800,
                availableSpaces: 456,
                vehicleRestrictions: VehicleRestrictions(maxHeight: 220, maxWidth: 200, maxLength: 520, maxWeight: 2200),
                amenities: [.roofed, .security, .evCharging, .washService, .toilet, .vendingMachine, .barrier],
                paymentMethods: [.cash, .creditCard, .ic, .qr, .app],
                lastUpdated: Date().addingTimeInterval(-15)
            )
        ]
    }
}