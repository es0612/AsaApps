//
//  LocationManager+Extensions.swift
//  AsaParkingFinder
//  
//  LocationManagerのCLLocationManagerDelegate実装
//

import Foundation
import CoreLocation

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("📍 位置情報を取得しました: \(locations.count)件")
        
        guard let location = locations.last else { 
            print("❌ 有効な位置情報がありません")
            return 
        }
        
        Task { @MainActor in
            self.currentLocation = location
            self.lastUpdated = Date()
            self.isLoadingLocation = false
            self.locationError = ""
            
            print("✅ 現在地: 緯度\(location.coordinate.latitude), 経度\(location.coordinate.longitude)")
            print("📏 精度: \(location.horizontalAccuracy)m")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 位置情報取得エラー: \(error.localizedDescription)")
        
        Task { @MainActor in
            self.isLoadingLocation = false
            
            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    self.locationError = "現在地を特定できません。しばらく待ってから再試行してください。"
                case .denied:
                    self.locationError = "位置情報へのアクセスが拒否されています。設定から許可してください。"
                case .network:
                    self.locationError = "ネットワーク接続を確認してください。"
                case .headingFailure:
                    self.locationError = "方向情報の取得に失敗しました。"
                case .rangingUnavailable, .rangingFailure:
                    self.locationError = "位置測定機能が利用できません。"
                case .promptDeclined:
                    self.locationError = "位置情報の使用が拒否されました。"
                default:
                    self.locationError = "位置情報の取得に失敗しました: \(clError.localizedDescription)"
                }
            } else {
                self.locationError = "位置情報の取得に失敗しました: \(error.localizedDescription)"
            }
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 位置情報許可状態が変更されました: \(manager.authorizationStatus.rawValue)")
        
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            self.updateLocationStatus()
            
            // 許可された場合は自動的に位置情報を取得
            if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                print("✅ 位置情報が許可されました。現在地を取得します...")
                self.requestCurrentLocation()
            }
        }
    }
}