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
    }
    
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
        isLocationEnabled = locationManager.isLocationEnabled
    }
    
    func saveCurrentLocation() {
        guard !locationName.isEmpty else {
            errorMessage = "位置の名前を入力してください"
            return
        }
        
        guard let currentLocation = locationManager.currentLocation else {
            errorMessage = "現在の位置を取得できませんでした"
            return
        }
        
        saveLocationManually(location: currentLocation)
    }
    
    func saveLocationManually(location: CLLocation) {
        let locationData = locationManager.createLocationData(from: location, name: locationName)
        
        if let context = modelContext {
            context.insert(locationData)
            try? context.save()
        }
        
        savedLocations.append(locationData)
        locationName = ""
        errorMessage = ""
    }
    
    func deleteLocation(_ location: LocationData) {
        if let context = modelContext {
            context.delete(location)
            try? context.save()
        }
        
        savedLocations.removeAll { $0.id == location.id }
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