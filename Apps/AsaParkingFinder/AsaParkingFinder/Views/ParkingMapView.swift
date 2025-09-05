//
//  ParkingMapView.swift
//  AsaParkingFinder
//  
//  駐車場検索用マップビュー
//  AsaLocationTrackerのLocationMapViewを改良
//

import SwiftUI
import MapKit
import AsaUIKit

struct ParkingMapView: View {
    @State var viewModel: ParkingFinderViewModel
    @State private var region: MKCoordinateRegion
    @State private var selectedParkingLot: ParkingLot?
    @State private var showingParkingDetail = false
    
    init(viewModel: ParkingFinderViewModel) {
        self.viewModel = viewModel
        self._region = State(initialValue: Self.calculateInitialRegion(
            userLocation: viewModel.currentLocation,
            parkingLots: viewModel.parkingLots
        ))
    }
    
    var body: some View {
        mainMapView
            .sheet(isPresented: $showingParkingDetail) {
                if let parkingLot = selectedParkingLot {
                    ParkingDetailSheet(
                        parkingLot: parkingLot,
                        distance: viewModel.getDistanceString(to: parkingLot),
                        viewModel: viewModel
                    )
                }
            }
    }
    
    private var mainMapView: some View {
        ZStack {
            mapWithAnnotations
            mapControlsOverlay
            searchRadiusOverlay
        }
    }
    
    private var mapWithAnnotations: some View {
        Map(coordinateRegion: $region, 
            interactionModes: .all,
            showsUserLocation: true,
            userTrackingMode: .none,
            annotationItems: viewModel.filteredAndSortedParkingLots) { parkingLot in
            MapAnnotation(coordinate: parkingLot.coordinate) {
                ParkingAnnotationView(
                    parkingLot: parkingLot,
                    isSelected: selectedParkingLot?.id == parkingLot.id
                ) {
                    selectedParkingLot = parkingLot
                    showingParkingDetail = true
                }
            }
        }
        .onAppear {
            updateRegionIfNeeded()
        }
        .onChange(of: viewModel.parkingLots) { oldValue, newValue in
            updateRegion(for: newValue)
        }
        .onChange(of: viewModel.currentLocation) { oldValue, newValue in
            if let location = newValue {
                updateRegionWithUserLocation(location)
            }
        }
    }
    
    private var mapControlsOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                mapControls
            }
            .padding(.trailing, 16)
            .padding(.bottom, 32)
        }
    }
    
    private var searchRadiusOverlay: some View {
        VStack {
            Spacer()
            HStack {
                searchRadiusIndicator
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Map Controls
    
    private var mapControls: some View {
        VStack(spacing: 12) {
            // 現在地ボタン
            Button {
                centerOnUserLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(AsaColors.coffeeBrown)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .disabled(viewModel.currentLocation == nil)
            
            // 検索結果を全表示ボタン
            Button {
                showAllParkingLots()
            } label: {
                Image(systemName: "scope")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(AsaColors.mutedSage)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .disabled(viewModel.parkingLots.isEmpty)
        }
    }
    
    // MARK: - Search Radius Indicator
    
    private var searchRadiusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(AsaColors.coffeeBrown.opacity(0.3))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(AsaColors.coffeeBrown, lineWidth: 2)
                )
            
            Text("検索範囲: \(formatDistance(viewModel.searchFilter.searchRadius))")
                .font(.caption)
                .foregroundColor(AsaColors.darkSlate)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Methods
    
    private static func calculateInitialRegion(userLocation: CLLocation?, parkingLots: [ParkingLot]) -> MKCoordinateRegion {
        if let userLocation = userLocation {
            return MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        } else {
            // デフォルト（東京駅）
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    private func updateRegionIfNeeded() {
        if let userLocation = viewModel.currentLocation {
            updateRegionWithUserLocation(userLocation)
        }
    }
    
    private func updateRegion(for parkingLots: [ParkingLot]) {
        guard !parkingLots.isEmpty else { return }
        
        let coordinates = parkingLots.map { $0.coordinate }
        
        // 現在地も含める
        var allCoordinates = coordinates
        if let userLocation = viewModel.currentLocation {
            allCoordinates.append(userLocation.coordinate)
        }
        
        let region = calculateRegion(for: allCoordinates)
        withAnimation(.easeInOut(duration: 0.5)) {
            self.region = region
        }
    }
    
    private func updateRegionWithUserLocation(_ location: CLLocation) {
        let newRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        withAnimation(.easeInOut(duration: 0.3)) {
            region = newRegion
        }
    }
    
    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return region // 現在の領域を維持
        }
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let deltaLat = max((maxLat - minLat) * 1.3, 0.005) // 最小範囲とマージン
        let deltaLon = max((maxLon - minLon) * 1.3, 0.005)
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: deltaLat, longitudeDelta: deltaLon)
        )
    }
    
    private func centerOnUserLocation() {
        guard let userLocation = viewModel.currentLocation else { return }
        updateRegionWithUserLocation(userLocation)
    }
    
    private func showAllParkingLots() {
        updateRegion(for: viewModel.filteredAndSortedParkingLots)
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return "\(Int(distance))m"
        }
    }
}

// MARK: - ParkingAnnotationView

struct ParkingAnnotationView: View {
    let parkingLot: ParkingLot
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // メインアイコン
            ZStack {
                Circle()
                    .fill(isSelected ? AsaColors.coffeeBrown : Color.white)
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 2) {
                    Image(systemName: "car.fill")
                        .font(.system(size: isSelected ? 14 : 12))
                        .foregroundColor(isSelected ? .white : AsaColors.coffeeBrown)
                    
                    if let available = parkingLot.availableSpaces {
                        Text("\(available)")
                            .font(.system(size: isSelected ? 10 : 8, weight: .bold))
                            .foregroundColor(isSelected ? .white : AsaColors.darkSlate)
                    }
                }
            }
            
            // 駐車場名
            if isSelected {
                Text(parkingLot.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(AsaColors.darkSlate)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - ParkingDetailSheet

struct ParkingDetailSheet: View {
    let parkingLot: ParkingLot
    let distance: String
    let viewModel: ParkingFinderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // ヘッダー情報
                    headerSection
                    
                    // 基本情報
                    basicInfoSection
                    
                    // アメニティ情報
                    if !parkingLot.amenities.isEmpty {
                        amenitiesSection
                    }
                    
                    // 支払い方法
                    if !parkingLot.paymentMethods.isEmpty {
                        paymentMethodsSection
                    }
                    
                    // 車両制限
                    if let restrictions = parkingLot.vehicleRestrictions {
                        vehicleRestrictionsSection(restrictions)
                    }
                    
                    // アクションボタン
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle(parkingLot.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var headerSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(distance)
                            .font(.headline)
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text("現在地から")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(parkingLot.displayRate)
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)
                        Text(parkingLot.operatingHours)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
                
                if let available = parkingLot.availableSpaces, let total = parkingLot.totalSpaces {
                    ProgressView(value: Double(total - available), total: Double(total))
                        .progressViewStyle(LinearProgressViewStyle(tint: available > 0 ? AsaColors.coffeeBrown : .red))
                    
                    Text("空き: \(available)台 / 全\(total)台")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("基本情報")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(parkingLot.address)
                        .font(.body)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Text("営業時間: \(parkingLot.operatingHours)")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
        }
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("設備・サービス")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(parkingLot.amenities, id: \.self) { amenity in
                    HStack {
                        Image(systemName: amenity.icon)
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text(amenity.rawValue)
                            .font(.caption)
                            .foregroundColor(AsaColors.darkSlate)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AsaColors.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("支払い方法")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            
            HStack {
                ForEach(parkingLot.paymentMethods, id: \.self) { method in
                    VStack {
                        Image(systemName: method.icon)
                            .font(.title2)
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text(method.rawValue)
                            .font(.caption2)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AsaColors.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private func vehicleRestrictionsSection(_ restrictions: VehicleRestrictions) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("車両制限")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            
            AsaCard {
                VStack(alignment: .leading, spacing: 4) {
                    if let height = restrictions.maxHeight {
                        Text("高さ制限: \(Int(height))cm")
                    }
                    if let width = restrictions.maxWidth {
                        Text("幅制限: \(Int(width))cm")
                    }
                    if let length = restrictions.maxLength {
                        Text("長さ制限: \(Int(length))cm")
                    }
                    if let weight = restrictions.maxWeight {
                        Text("重量制限: \(Int(weight))kg")
                    }
                }
                .font(.caption)
                .foregroundColor(AsaColors.darkSlate)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            AsaButton(
                title: "経路案内",
                action: {
                    viewModel.openInMaps(parkingLot: parkingLot)
                    dismiss()
                },
                color: AsaColors.coffeeBrown
            )
            
            AsaButton(
                title: "空き状況を更新",
                action: {
                    Task {
                        await viewModel.updateParkingAvailability(for: parkingLot)
                    }
                },
                color: AsaColors.mutedSage
            )
        }
    }
}