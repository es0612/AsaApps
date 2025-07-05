import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled: Bool = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            errorMessage = "位置情報のアクセス許可が必要です"
            return
        }
        
        locationManager.requestLocation()
    }
    
    func requestPermission() {
        print("🔐 LocationManager: requestPermission() called")
        print("🔐 Current authorization status: \(authorizationStatus.rawValue)")
        locationManager.requestWhenInUseAuthorization()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        self.location = location
        self.errorMessage = nil
        
        DispatchQueue.main.async {
            self.isLocationEnabled = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "位置情報の取得に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔐 LocationManager: didChangeAuthorization called with status: \(status.rawValue)")
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .notDetermined:
                print("🔐 Status: notDetermined")
                self.isLocationEnabled = false
            case .restricted, .denied:
                print("🔐 Status: restricted/denied")
                self.isLocationEnabled = false
                self.errorMessage = "位置情報のアクセスが拒否されています。設定から許可してください。"
            case .authorizedWhenInUse, .authorizedAlways:
                print("🔐 Status: authorized! Requesting location...")
                self.isLocationEnabled = true
                self.errorMessage = nil
                self.requestLocation()
            @unknown default:
                print("🔐 Status: unknown")
                self.isLocationEnabled = false
            }
        }
    }
}