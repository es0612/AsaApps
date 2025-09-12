//
//  AddEventView.swift
//  AsaEventMap
//  
//  Created on 2025/09/12
//

import SwiftUI
import MapKit

struct AddEventView: View {
    @Bindable var viewModel: EventMapViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var eventDescription = ""
    @State private var date = Date()
    @State private var category: EventCategory = .other
    @State private var address = ""
    @State private var coordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showingMapPicker = false
    @State private var showingValidationAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                Section(header: Text("基本情報")) {
                    TextField("イベント名", text: $title)
                    
                    DatePicker("日時", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    
                    Picker("カテゴリ", selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                }
                
                // Description Section
                Section(header: Text("詳細")) {
                    TextField("説明（任意）", text: $eventDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Location Section
                Section(header: Text("場所")) {
                    TextField("住所", text: $address)
                    
                    // Map Preview
                    Map(position: .constant(.region(region))) {
                        Marker("選択位置", coordinate: coordinate)
                            .tint(category.color)
                    }
                    .frame(height: 150)
                    .cornerRadius(10)
                    .onTapGesture {
                        showingMapPicker = true
                    }
                    
                    HStack {
                        AsaButton(
                            title: "地図で選択",
                            action: {
                                showingMapPicker = true
                            },
                            color: Color("AsaMocha")
                        )
                        
                        if let currentLocation = viewModel.currentLocation {
                            AsaButton(
                                title: "現在地を使用",
                                action: {
                                    coordinate = currentLocation
                                    region.center = currentLocation
                                    reverseGeocode(coordinate: currentLocation)
                                },
                                color: Color("AsaMutedSage")
                            )
                        }
                    }
                }
            }
            .navigationTitle("新規イベント")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveEvent()
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingMapPicker) {
                MapPickerView(coordinate: $coordinate, region: $region, address: $address)
            }
            .alert("入力エラー", isPresented: $showingValidationAlert) {
                Button("OK") {}
            } message: {
                Text("イベント名を入力してください")
            }
        }
    }
    
    // MARK: - Save Event
    private func saveEvent() {
        guard !title.isEmpty else {
            showingValidationAlert = true
            return
        }
        
        let newEvent = Event(
            title: title,
            eventDescription: eventDescription,
            date: date,
            category: category,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            address: address
        )
        
        viewModel.addEvent(newEvent)
        dismiss()
    }
    
    // MARK: - Reverse Geocoding
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var addressComponents: [String] = []
                
                if let locality = placemark.locality {
                    addressComponents.append(locality)
                }
                if let administrativeArea = placemark.administrativeArea {
                    addressComponents.append(administrativeArea)
                }
                if let country = placemark.country {
                    addressComponents.append(country)
                }
                
                address = addressComponents.joined(separator: ", ")
            }
        }
    }
}

// MARK: - Map Picker View
struct MapPickerView: View {
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var region: MKCoordinateRegion
    @Binding var address: String
    @Environment(\.dismiss) private var dismiss
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationStack {
            ZStack {
                MapReader { reader in
                    Map(position: .constant(.region(region))) {
                        if let tappedCoordinate = tappedCoordinate {
                            Marker("選択位置", coordinate: tappedCoordinate)
                                .tint(Color("AsaCoffeeBrown"))
                        }
                    }
                    .onTapGesture { location in
                        if let coordinate = reader.convert(location, from: .local) {
                            tappedCoordinate = coordinate
                            self.coordinate = coordinate
                            region.center = coordinate
                            reverseGeocode(coordinate: coordinate)
                        }
                    }
                }
                
                // Instructions
                VStack {
                    Text("地図をタップして位置を選択")
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .shadow(radius: 3)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("位置を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(tappedCoordinate == nil)
                }
            }
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var addressComponents: [String] = []
                
                if let locality = placemark.locality {
                    addressComponents.append(locality)
                }
                if let administrativeArea = placemark.administrativeArea {
                    addressComponents.append(administrativeArea)
                }
                
                address = addressComponents.joined(separator: ", ")
            }
        }
    }
}

// MARK: - Temporary Location for Map Annotation
struct TempLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    AddEventView(viewModel: EventMapViewModel())
}