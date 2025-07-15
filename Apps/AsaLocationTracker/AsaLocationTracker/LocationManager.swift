//
//  LocationManager.swift
//  AsaLocationTracker
//  
//  Created on 2025/07/12
//


import Foundation
import CoreLocation
import SwiftUI

@MainActor
class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isLocationEnabled: Bool = false
    @Published var isLoadingLocation: Bool = false
    @Published var locationError: String = ""
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
        isLocationEnabled = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        
        // 初期状態のエラーメッセージを設定
        switch authorizationStatus {
        case .notDetermined:
            locationError = ""
        case .denied, .restricted:
            locationError = "位置情報へのアクセスが拒否されています"
        case .authorizedWhenInUse, .authorizedAlways:
            locationError = ""
        @unknown default:
            locationError = "不明な位置情報許可状態です"
        }
        
        print("LocationManager初期化: \(authorizationStatus.rawValue) (\(statusDescription(authorizationStatus)))")
    }
    
    func requestLocationPermission() {
        print("位置情報許可をリクエスト中...")
        
        guard authorizationStatus == .notDetermined else {
            print("既に許可状態が決定済み: \(statusDescription(authorizationStatus))")
            return
        }
        
        manager.requestWhenInUseAuthorization()
        print("requestWhenInUseAuthorization()を呼び出しました")
    }
    
    func startLocationUpdates() {
        guard isLocationEnabled else { return }
        manager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        manager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() {
        print("現在位置取得を試行中...")
        print("現在の許可状態: \(statusDescription(authorizationStatus))")
        print("isLocationEnabled: \(isLocationEnabled)")
        
        guard isLocationEnabled else { 
            locationError = "位置情報の許可が必要です"
            print("位置情報が許可されていないため取得中止")
            return 
        }
        
        isLoadingLocation = true
        locationError = ""
        manager.requestLocation()
        print("requestLocation()を呼び出しました")
    }
    
    func createLocationData(from location: CLLocation, name: String) -> LocationData {
        return LocationData(from: location, name: name)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            self.currentLocation = location
            self.isLoadingLocation = false
            self.locationError = ""
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLoadingLocation = false
            self.locationError = "位置情報の取得に失敗しました: \(error.localizedDescription)"
            print("Location manager failed with error: \(error)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            print("位置情報許可状態変更: \(status.rawValue) (\(self.statusDescription(status)))")
            
            self.authorizationStatus = status
            self.isLocationEnabled = status == .authorizedWhenInUse || status == .authorizedAlways
            
            switch status {
            case .notDetermined:
                self.locationError = ""
            case .denied, .restricted:
                self.locationError = "位置情報へのアクセスが拒否されています"
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = ""
            @unknown default:
                self.locationError = "不明な位置情報許可状態です"
            }
        }
    }
    
    private func statusDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "未決定"
        case .denied: return "拒否"
        case .restricted: return "制限"
        case .authorizedWhenInUse: return "使用中のみ許可"
        case .authorizedAlways: return "常に許可"
        @unknown default: return "不明"
        }
    }
}