//
//  LocationData.swift
//  AsaLocationTracker
//  
//  Created on 2025/07/12
//


import Foundation
import SwiftData
import CoreLocation

@Model
final class LocationData {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var name: String
    
    init(latitude: Double, longitude: Double, timestamp: Date, name: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.name = name
    }
    
    convenience init(from location: CLLocation, name: String) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp,
            name: name
        )
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
