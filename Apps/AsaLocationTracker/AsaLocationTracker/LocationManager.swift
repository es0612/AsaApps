//
//  LocationManager.swift
//  AsaLocationTracker
//  
//  Created on 2025/07/12
//


import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isLocationEnabled: Bool = false
    
    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
        isLocationEnabled = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard isLocationEnabled else { return }
        manager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        manager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() {
        guard isLocationEnabled else { return }
        manager.requestLocation()
    }
    
    func createLocationData(from location: CLLocation, name: String) -> LocationData {
        return LocationData(from: location, name: name)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        isLocationEnabled = status == .authorizedWhenInUse || status == .authorizedAlways
    }
}