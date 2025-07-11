//
//  AsaLocationTrackerTests.swift
//  AsaLocationTrackerTests
//  
//  Created on 2025/07/12
//


import Testing
import CoreLocation
@testable import AsaLocationTracker

struct AsaLocationTrackerTests {

    @Test func locationDataInitialization() async throws {
        let latitude = 35.6762
        let longitude = 139.6503
        let timestamp = Date()
        let name = "東京駅"
        
        let locationData = LocationData(
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            name: name
        )
        
        #expect(locationData.latitude == latitude)
        #expect(locationData.longitude == longitude)
        #expect(locationData.timestamp == timestamp)
        #expect(locationData.name == name)
    }
    
    @Test func locationDataCoordinateConversion() async throws {
        let latitude = 35.6762
        let longitude = 139.6503
        let locationData = LocationData(
            latitude: latitude,
            longitude: longitude,
            timestamp: Date(),
            name: "テスト地点"
        )
        
        let coordinate = locationData.coordinate
        #expect(coordinate.latitude == latitude)
        #expect(coordinate.longitude == longitude)
    }
    
    @Test func locationDataFromCLLocation() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        let clLocation = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, timestamp: Date())
        
        let locationData = LocationData(from: clLocation, name: "CLLocationから作成")
        
        #expect(locationData.latitude == coordinate.latitude)
        #expect(locationData.longitude == coordinate.longitude)
        #expect(locationData.name == "CLLocationから作成")
    }
    
    @Test func locationManagerInitialization() async throws {
        let locationManager = LocationManager()
        
        #expect(locationManager.authorizationStatus == .notDetermined)
        #expect(locationManager.currentLocation == nil)
        #expect(locationManager.isLocationEnabled == false)
    }
    
    @Test func locationManagerRequestPermission() async throws {
        let locationManager = LocationManager()
        
        locationManager.requestLocationPermission()
        
        #expect(locationManager.authorizationStatus != .notDetermined)
    }
    
    @Test func locationManagerSaveLocation() async throws {
        let locationManager = LocationManager()
        let coordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        let testLocation = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, timestamp: Date())
        
        let locationData = locationManager.createLocationData(from: testLocation, name: "テスト位置")
        
        #expect(locationData.latitude == coordinate.latitude)
        #expect(locationData.longitude == coordinate.longitude)
        #expect(locationData.name == "テスト位置")
    }
    
    @Test func locationViewModelInitialization() async throws {
        await MainActor.run {
            let viewModel = LocationViewModel()
            
            #expect(viewModel.locationName.isEmpty)
            #expect(viewModel.savedLocations.isEmpty)
            #expect(viewModel.isLocationEnabled == false)
        }
    }
    
    @Test func locationViewModelSaveCurrentLocation() async throws {
        await MainActor.run {
            let viewModel = LocationViewModel()
            let coordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
            let testLocation = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, timestamp: Date())
            
            viewModel.locationName = "テスト地点"
            viewModel.saveLocationManually(location: testLocation)
            
            #expect(viewModel.savedLocations.count == 1)
            #expect(viewModel.savedLocations.first?.name == "テスト地点")
            #expect(viewModel.locationName.isEmpty)
        }
    }
    
    @Test func locationViewModelDeleteLocation() async throws {
        await MainActor.run {
            let viewModel = LocationViewModel()
            let coordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
            let testLocation = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, timestamp: Date())
            
            viewModel.locationName = "削除テスト"
            viewModel.saveLocationManually(location: testLocation)
            
            #expect(viewModel.savedLocations.count == 1)
            
            if let locationToDelete = viewModel.savedLocations.first {
                viewModel.deleteLocation(locationToDelete)
            }
            
            #expect(viewModel.savedLocations.isEmpty)
        }
    }
    
    @Test func mapViewInitialization() async throws {
        let locations = [
            LocationData(latitude: 35.6762, longitude: 139.6503, timestamp: Date(), name: "東京駅"),
            LocationData(latitude: 35.6596, longitude: 139.7006, timestamp: Date(), name: "東京タワー")
        ]
        
        let mapView = LocationMapView(locations: locations)
        
        #expect(mapView.locations.count == 2)
        #expect(mapView.locations.first?.name == "東京駅")
    }
    
    @Test func mapViewRegionCalculation() async throws {
        let locations = [
            LocationData(latitude: 35.6762, longitude: 139.6503, timestamp: Date(), name: "東京駅"),
            LocationData(latitude: 35.6596, longitude: 139.7006, timestamp: Date(), name: "東京タワー")
        ]
        
        let mapView = LocationMapView(locations: locations)
        let region = mapView.calculateRegion()
        
        #expect(region.center.latitude > 35.65)
        #expect(region.center.latitude < 35.68)
        #expect(region.center.longitude > 139.65)
        #expect(region.center.longitude < 139.71)
    }

}
