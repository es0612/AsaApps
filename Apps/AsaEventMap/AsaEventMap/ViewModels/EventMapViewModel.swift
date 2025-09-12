//
//  EventMapViewModel.swift
//  AsaEventMap
//  
//  Created on 2025/09/12
//

import Foundation
import SwiftUI
import SwiftData
import MapKit
import CoreLocation

@Observable
class EventMapViewModel: NSObject {
    private var modelContext: ModelContext?
    
    // MARK: - Properties
    var events: [Event] = []
    var filteredEvents: [Event] = []
    var selectedEvent: Event?
    var selectedCategory: EventCategory?
    var searchText = ""
    var isShowingAddEvent = false
    var isShowingEventDetail = false
    
    // Map properties
    var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // Location Manager
    private let locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        loadEvents()
    }
    
    // MARK: - Setup
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadEvents()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Data Loading
    func loadEvents() {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Event>(
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            events = try modelContext.fetch(descriptor)
            applyFilters()
        } catch {
            print("イベントの読み込みに失敗しました: \(error)")
        }
    }
    
    // MARK: - Filtering
    func applyFilters() {
        var filtered = events
        
        // カテゴリフィルター
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 検索フィルター
        if !searchText.isEmpty {
            filtered = filtered.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.eventDescription.localizedCaseInsensitiveContains(searchText) ||
                event.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredEvents = filtered
    }
    
    func clearFilters() {
        selectedCategory = nil
        searchText = ""
        applyFilters()
    }
    
    // MARK: - Event Management
    func addEvent(_ event: Event) {
        guard let modelContext = modelContext else { return }
        
        modelContext.insert(event)
        saveContext()
        loadEvents()
    }
    
    func updateEvent(_ event: Event) {
        event.updatedAt = Date()
        saveContext()
        loadEvents()
    }
    
    func deleteEvent(_ event: Event) {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(event)
        saveContext()
        loadEvents()
    }
    
    // MARK: - Map Functions
    func centerMapOnEvent(_ event: Event) {
        withAnimation {
            region = MKCoordinateRegion(
                center: event.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        selectedEvent = event
    }
    
    func centerMapOnAllEvents() {
        guard !filteredEvents.isEmpty else { return }
        
        let coordinates = filteredEvents.map { $0.coordinate }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let latDelta = max(maxLat - minLat, 0.01) * 1.2
        let lonDelta = max(maxLon - minLon, 0.01) * 1.2
        
        withAnimation {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        }
    }
    
    func centerMapOnCurrentLocation() {
        guard let currentLocation = currentLocation else { return }
        
        withAnimation {
            region = MKCoordinateRegion(
                center: currentLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    // MARK: - Statistics
    var upcomingEvents: [Event] {
        events.filter { $0.isUpcoming }.prefix(5).map { $0 }
    }
    
    var todayEvents: [Event] {
        events.filter { $0.isToday }
    }
    
    var eventsByCategory: [(EventCategory, Int)] {
        Dictionary(grouping: events, by: { $0.category })
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }
    
    // MARK: - Private Methods
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
        } catch {
            print("データの保存に失敗しました: \(error)")
        }
    }
    
    // MARK: - Sample Data
    func createSampleData() {
        let sampleEvents = [
            Event(
                title: "SwiftUI勉強会",
                eventDescription: "SwiftUIの最新機能について学ぶ勉強会",
                date: Date().addingTimeInterval(86400),
                category: .workshop,
                latitude: 35.6812,
                longitude: 139.7671,
                address: "東京都渋谷区"
            ),
            Event(
                title: "チームミーティング",
                eventDescription: "月次チームミーティング",
                date: Date().addingTimeInterval(172800),
                category: .meeting,
                latitude: 35.6762,
                longitude: 139.6503,
                address: "東京都千代田区"
            ),
            Event(
                title: "夏祭り",
                eventDescription: "地域の夏祭りイベント",
                date: Date().addingTimeInterval(259200),
                category: .festival,
                latitude: 35.6938,
                longitude: 139.7034,
                address: "東京都新宿区"
            )
        ]
        
        for event in sampleEvents {
            addEvent(event)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension EventMapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置情報の取得に失敗しました: \(error)")
    }
}