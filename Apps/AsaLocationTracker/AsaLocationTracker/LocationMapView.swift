//
//  LocationMapView.swift
//  AsaLocationTracker
//  
//  Created on 2025/07/12
//


import SwiftUI
import MapKit
import CoreLocation

struct LocationMapView: View {
    let locations: [LocationData]
    @State private var region: MKCoordinateRegion
    
    init(locations: [LocationData]) {
        self.locations = locations
        self._region = State(initialValue: Self.calculateRegion(for: locations))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locations) { location in
            MapAnnotation(coordinate: location.coordinate) {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title)
                        .shadow(radius: 2)
                    Text(location.name)
                        .font(.caption)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .padding(4)
                        .background(Color("AsaSoftCream").opacity(0.9))
                        .cornerRadius(6)
                        .shadow(radius: 1)
                }
            }
        }
        .onChange(of: locations) { newLocations in
            region = Self.calculateRegion(for: newLocations)
        }
    }
    
    func calculateRegion() -> MKCoordinateRegion {
        Self.calculateRegion(for: locations)
    }
    
    private static func calculateRegion(for locations: [LocationData]) -> MKCoordinateRegion {
        guard !locations.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        let coordinates = locations.map { $0.coordinate }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let latDelta = max(maxLat - minLat, 0.01) * 1.2
        let lonDelta = max(maxLon - minLon, 0.01) * 1.2
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}

#Preview {
    LocationMapView(locations: [
        LocationData(latitude: 35.6762, longitude: 139.6503, timestamp: Date(), name: "東京駅"),
        LocationData(latitude: 35.6596, longitude: 139.7006, timestamp: Date(), name: "東京タワー")
    ])
}