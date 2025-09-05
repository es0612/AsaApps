//
//  ParkingFinderViewModel.swift
//  AsaParkingFinder
//  
//  駐車場検索のメインビューモデル
//  @Observableパターン採用
//

import Foundation
import CoreLocation
import SwiftUI

@Observable
@MainActor
final class ParkingFinderViewModel {
    
    // MARK: - Dependencies
    
    private let locationManager = LocationManager()
    private let parkingService: ParkingServiceProtocol
    
    // MARK: - Published Properties
    
    var parkingLots: [ParkingLot] = []
    var selectedParkingLot: ParkingLot?
    var searchFilter = SearchFilter()
    var isSearching: Bool = false
    var hasSearched: Bool = false
    var errorMessage: String?
    var showingErrorAlert: Bool = false
    
    // 表示モード
    var displayMode: DisplayMode = .list
    
    // 距離計算結果のキャッシュ
    private var distanceCache: [String: CLLocationDistance] = [:]
    
    // MARK: - Computed Properties
    
    var isLocationEnabled: Bool {
        locationManager.isLocationEnabled
    }
    
    var currentLocation: CLLocation? {
        locationManager.currentLocation
    }
    
    var locationError: String {
        locationManager.locationError
    }
    
    var filteredAndSortedParkingLots: [ParkingLot] {
        let filtered = parkingLots.filter { searchFilter.matches($0) }
        return searchFilter.sortBy.sort(filtered, userLocation: currentLocation)
    }
    
    var searchResultSummary: String {
        let totalCount = parkingLots.count
        let filteredCount = filteredAndSortedParkingLots.count
        
        if !hasSearched {
            return "検索を開始してください"
        } else if totalCount == 0 {
            return "駐車場が見つかりませんでした"
        } else if totalCount == filteredCount {
            return "\(totalCount)件の駐車場"
        } else {
            return "\(totalCount)件中\(filteredCount)件を表示"
        }
    }
    
    // MARK: - Initialization
    
    init(parkingService: ParkingServiceProtocol = MockParkingService()) {
        self.parkingService = parkingService
        print("🚗 ParkingFinderViewModel初期化完了")
        
        // 初期位置情報取得の試行
        requestLocationIfNeeded()
    }
    
    // MARK: - Location Methods
    
    func requestLocationPermission() {
        print("🚗 位置情報許可をリクエスト")
        locationManager.requestLocationPermission()
    }
    
    func requestCurrentLocation() {
        print("🚗 現在地取得開始")
        locationManager.requestCurrentLocation()
    }
    
    private func requestLocationIfNeeded() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestLocationPermission()
        } else if locationManager.isLocationEnabled && locationManager.currentLocation == nil {
            locationManager.requestCurrentLocation()
        }
    }
    
    // MARK: - Search Methods
    
    func searchNearbyParkingLots() async {
        print("🚗 駐車場検索開始")
        
        guard let location = locationManager.currentLocation else {
            handleError(.noLocation)
            return
        }
        
        await performSearch(center: location.coordinate)
    }
    
    func searchParkingLots(at coordinate: CLLocationCoordinate2D) async {
        print("🚗 指定座標での駐車場検索: (\(coordinate.latitude), \(coordinate.longitude))")
        await performSearch(center: coordinate)
    }
    
    private func performSearch(center: CLLocationCoordinate2D) async {
        isSearching = true
        errorMessage = nil
        distanceCache.removeAll()
        
        do {
            let results = try await parkingService.searchParking(
                center: center,
                radius: searchFilter.searchRadius,
                filter: searchFilter
            )
            
            parkingLots = results
            hasSearched = true
            
            // 距離を事前計算してキャッシュ
            if let userLocation = locationManager.currentLocation {
                for lot in results {
                    let distance = userLocation.distance(from: CLLocation(
                        latitude: lot.coordinate.latitude, 
                        longitude: lot.coordinate.longitude
                    ))
                    distanceCache[lot.id] = distance
                }
            }
            
            print("✅ 検索完了: \(results.count)件の駐車場を取得")
            
        } catch let error as ParkingServiceError {
            handleError(.parkingServiceError(error))
        } catch {
            handleError(.unknownError(error.localizedDescription))
        }
        
        isSearching = false
    }
    
    func refreshSearch() async {
        print("🚗 検索結果を更新")
        await searchNearbyParkingLots()
    }
    
    // MARK: - Filter and Sort Methods
    
    func updateSearchRadius(_ radius: CLLocationDistance) {
        print("🚗 検索範囲を更新: \(Int(radius))m")
        searchFilter.searchRadius = radius
        locationManager.setSearchRadius(radius)
    }
    
    func clearAllFilters() {
        print("🚗 全フィルターをクリア")
        searchFilter.clearAllFilters()
    }
    
    func applyQuickFilter(_ option: QuickFilterOption) {
        print("🚗 クイックフィルター適用: \(option.rawValue)")
        
        switch option {
        case .nearbyOnly:
            searchFilter.searchRadius = 500
        case .affordable:
            searchFilter.maxHourlyRate = 200
            searchFilter.maxDailyRate = 1500
        case .available:
            searchFilter.showOnlyAvailable = true
        case .roofed:
            searchFilter.requiredAmenities.insert(.roofed)
        case .evCharging:
            searchFilter.requiredAmenities.insert(.evCharging)
        }
    }
    
    // MARK: - Parking Lot Details
    
    func selectParkingLot(_ lot: ParkingLot) {
        print("🚗 駐車場を選択: \(lot.name)")
        selectedParkingLot = lot
    }
    
    func getDistance(to lot: ParkingLot) -> CLLocationDistance? {
        if let cached = distanceCache[lot.id] {
            return cached
        }
        
        guard let userLocation = locationManager.currentLocation else { return nil }
        
        let distance = userLocation.distance(from: CLLocation(
            latitude: lot.coordinate.latitude,
            longitude: lot.coordinate.longitude
        ))
        
        distanceCache[lot.id] = distance
        return distance
    }
    
    func getDistanceString(to lot: ParkingLot) -> String {
        guard let distance = getDistance(to: lot) else { return "距離不明" }
        
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    func updateParkingAvailability(for lot: ParkingLot) async {
        print("🚗 駐車場の空き状況を更新: \(lot.name)")
        
        do {
            if let updatedLot = try await parkingService.updateAvailability(id: lot.id) {
                // 配列内の該当駐車場を更新
                if let index = parkingLots.firstIndex(where: { $0.id == lot.id }) {
                    parkingLots[index] = updatedLot
                }
                
                // 選択中の駐車場も更新
                if selectedParkingLot?.id == lot.id {
                    selectedParkingLot = updatedLot
                }
                
                print("✅ 空き状況更新完了: \(updatedLot.availableSpaces ?? 0)台")
            }
        } catch let error as ParkingServiceError {
            handleError(.parkingServiceError(error))
        } catch {
            handleError(.unknownError(error.localizedDescription))
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: ViewModelError) {
        print("❌ エラー発生: \(error.localizedDescription)")
        errorMessage = error.localizedDescription
        showingErrorAlert = true
    }
    
    func dismissError() {
        errorMessage = nil
        showingErrorAlert = false
    }
    
    // MARK: - Helper Methods
    
    func refreshLocation() {
        print("🚗 位置情報を再取得")
        locationManager.refreshLocation()
    }
    
    func openInMaps(parkingLot: ParkingLot) {
        print("🚗 マップアプリで開く: \(parkingLot.name)")
        
        let coordinate = parkingLot.coordinate
        let url = URL(string: "http://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)&dirflg=d")!
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            handleError(.mapAppNotAvailable)
        }
    }
}

// MARK: - Supporting Types

enum DisplayMode: String, CaseIterable, Identifiable {
    case list = "リスト"
    case map = "マップ"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .map: return "map"
        }
    }
}

enum QuickFilterOption: String, CaseIterable {
    case nearbyOnly = "近距離のみ"
    case affordable = "格安料金"
    case available = "空きあり"
    case roofed = "屋根付き"
    case evCharging = "EV充電"
    
    var systemImage: String {
        switch self {
        case .nearbyOnly: return "location.circle"
        case .affordable: return "yensign.circle"
        case .available: return "car.circle"
        case .roofed: return "building.2.crop.circle"
        case .evCharging: return "bolt.car.circle"
        }
    }
}

enum ViewModelError: LocalizedError {
    case noLocation
    case parkingServiceError(ParkingServiceError)
    case unknownError(String)
    case mapAppNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .noLocation:
            return "現在地が取得できません。位置情報を有効にして再試行してください。"
        case .parkingServiceError(let serviceError):
            return serviceError.localizedDescription
        case .unknownError(let message):
            return "予期しないエラーが発生しました: \(message)"
        case .mapAppNotAvailable:
            return "マップアプリを開けませんでした。"
        }
    }
}