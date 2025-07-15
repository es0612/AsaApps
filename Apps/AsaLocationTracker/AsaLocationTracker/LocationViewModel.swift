//
//  LocationViewModel.swift
//  AsaLocationTracker
//  
//  Created on 2025/07/12
//


import Foundation
import CoreLocation
import SwiftData

@MainActor
class LocationViewModel: ObservableObject {
    @Published var locationName: String = ""
    @Published var savedLocations: [LocationData] = []
    @Published var isLocationEnabled: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoadingLocation: Bool = false
    @Published var hasCurrentLocation: Bool = false
    @Published var authorizationStatus: String = ""
    
    private let locationManager = LocationManager()
    private var modelContext: ModelContext?
    
    init() {
        setupLocationManager()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSavedLocations()
    }
    
    private func setupLocationManager() {
        isLocationEnabled = locationManager.isLocationEnabled
        
        // LocationManagerの状態変化を監視
        locationManager.$isLocationEnabled
            .assign(to: &$isLocationEnabled)
        
        locationManager.$isLoadingLocation
            .assign(to: &$isLoadingLocation)
        
        locationManager.$locationError
            .assign(to: &$errorMessage)
        
        // 現在位置の取得状態を監視
        locationManager.$currentLocation
            .map { $0 != nil }
            .assign(to: &$hasCurrentLocation)
        
        // 許可状態の詳細情報を監視
        locationManager.$authorizationStatus
            .map { status in
                switch status {
                case .notDetermined: return "未決定"
                case .denied: return "拒否"
                case .restricted: return "制限"
                case .authorizedWhenInUse: return "使用中のみ許可"
                case .authorizedAlways: return "常に許可"
                @unknown default: return "不明(\(status.rawValue))"
                }
            }
            .assign(to: &$authorizationStatus)
    }
    
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
        // 状態は locationManager からの Publisher で自動更新される
    }
    
    func saveCurrentLocation() {
        guard !locationName.isEmpty else {
            errorMessage = "位置の名前を入力してください"
            return
        }
        
        guard let currentLocation = locationManager.currentLocation else {
            errorMessage = "位置情報が取得されていません。「現在の位置を取得」ボタンを押してください"
            return
        }
        
        saveLocationManually(location: currentLocation)
    }
    
    func saveLocationManually(location: CLLocation) {
        let locationData = locationManager.createLocationData(from: location, name: locationName)
        
        guard let context = modelContext else {
            errorMessage = "データベースの接続に問題があります"
            return
        }
        
        do {
            context.insert(locationData)
            try context.save()
            savedLocations.append(locationData)
            locationName = ""
            errorMessage = ""
        } catch {
            errorMessage = "位置の保存に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func deleteLocation(_ location: LocationData) {
        guard let context = modelContext else {
            errorMessage = "データベースの接続に問題があります"
            return
        }
        
        do {
            context.delete(location)
            try context.save()
            savedLocations.removeAll { $0.id == location.id }
        } catch {
            errorMessage = "位置の削除に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func getCurrentLocation() {
        locationManager.getCurrentLocation()
    }
    
    private func loadSavedLocations() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<LocationData>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            savedLocations = try context.fetch(descriptor)
        } catch {
            errorMessage = "保存された位置の読み込みに失敗しました: \(error.localizedDescription)"
        }
    }
}