//
//  LocationManager.swift
//  AsaParkingFinder
//  
//  駐車場検索用に最適化されたLocationManager
//  AsaLocationTrackerからの改良版
//

import Foundation
import CoreLocation
import SwiftUI

@Observable
@MainActor
final class LocationManager: NSObject {
    
    // MARK: - Properties
    
    private let manager = CLLocationManager()
    
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var isLocationEnabled: Bool = false
    var isLoadingLocation: Bool = false
    var locationError: String = ""
    var lastUpdated: Date?
    
    // 駐車場検索に特化したプロパティ
    var searchRadius: CLLocationDistance = 1000.0 // デフォルト1km
    var locationAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
        updateLocationStatus()
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        manager.delegate = self
        manager.desiredAccuracy = locationAccuracy
        authorizationStatus = manager.authorizationStatus
        
        print("📍 LocationManager初期化: \(authorizationStatus.rawValue) (\(statusDescription))")
    }
    
    func updateLocationStatus() {
        isLocationEnabled = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        updateErrorMessage()
    }
    
    func updateErrorMessage() {
        switch authorizationStatus {
        case .notDetermined:
            locationError = ""
        case .denied:
            locationError = "位置情報へのアクセスが拒否されています。設定から許可してください。"
        case .restricted:
            locationError = "位置情報のアクセスが制限されています。"
        case .authorizedWhenInUse, .authorizedAlways:
            locationError = ""
        @unknown default:
            locationError = "不明な位置情報許可状態です。"
        }
    }
    
    private var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined: return "未決定"
        case .denied: return "拒否"
        case .restricted: return "制限"
        case .authorizedWhenInUse: return "使用中のみ許可"
        case .authorizedAlways: return "常に許可"
        @unknown default: return "不明"
        }
    }
    
    // MARK: - Public Methods
    
    /// 位置情報の許可をリクエスト
    func requestLocationPermission() {
        print("📍 位置情報許可をリクエスト中...")
        
        guard authorizationStatus == .notDetermined else {
            print("📍 既に許可状態が決定済み: \(statusDescription)")
            return
        }
        
        manager.requestWhenInUseAuthorization()
    }
    
    /// 現在地を取得（駐車場検索用に最適化）
    func requestCurrentLocation() {
        print("📍 現在地取得開始...")
        
        guard isLocationEnabled else {
            locationError = "位置情報の許可が必要です"
            print("❌ 位置情報が許可されていません")
            return
        }
        
        guard !isLoadingLocation else {
            print("⚠️ 既に位置情報を取得中です")
            return
        }
        
        isLoadingLocation = true
        locationError = ""
        
        // 駐車場検索に最適な精度設定
        manager.desiredAccuracy = locationAccuracy
        manager.requestLocation()
    }
    
    /// 位置情報の精度設定を変更
    func updateLocationAccuracy(_ accuracy: CLLocationAccuracy) {
        locationAccuracy = accuracy
        manager.desiredAccuracy = accuracy
        print("📍 位置情報精度を更新: \(accuracy)m")
    }
    
    /// 検索範囲の設定
    func setSearchRadius(_ radius: CLLocationDistance) {
        searchRadius = radius
        print("📍 検索範囲を設定: \(Int(radius))m")
    }
    
    /// 位置情報の有効性をチェック
    func isLocationValid() -> Bool {
        guard let location = currentLocation else { return false }
        
        // 位置情報が5分以内に取得されたものかチェック
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        return location.timestamp > fiveMinutesAgo
    }
    
    /// 強制的に位置情報を再取得
    func refreshLocation() {
        print("📍 位置情報を強制更新...")
        currentLocation = nil
        lastUpdated = nil
        requestCurrentLocation()
    }
    
    /// 指定した座標からの距離を計算
    func calculateDistance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: targetLocation)
    }
}