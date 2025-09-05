//
//  FilterSheet.swift
//  AsaParkingFinder
//  
//  駐車場検索フィルター設定画面
//

import SwiftUI
import AsaUIKit
import CoreLocation

struct FilterSheet: View {
    @State var searchFilter: SearchFilter
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingVehicleSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 検索範囲設定
                    searchRadiusSection
                    
                    // 料金フィルター
                    priceFilterSection
                    
                    // 設備・サービス
                    amenitiesSection
                    
                    // 支払い方法
                    paymentMethodsSection
                    
                    // 車両制限設定
                    vehicleRestrictionsSection
                    
                    // その他のオプション
                    otherOptionsSection
                    
                    // クイックフィルター
                    quickFiltersSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("検索フィルター")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("リセット") {
                        searchFilter.clearAllFilters()
                    }
                    .foregroundColor(AsaColors.mutedSage)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("適用") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Search Radius Section
    
    private var searchRadiusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("検索範囲")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            
            AsaCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("現在地から")
                            .font(.subheadline)
                            .foregroundColor(AsaColors.darkSlate)
                        Spacer()
                        Text(formatDistance(searchFilter.searchRadius))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { searchFilter.searchRadius },
                            set: { searchFilter.searchRadius = $0 }
                        ),
                        in: 500...5000,
                        step: 500
                    ) {
                        Text("検索範囲")
                    }
                    .tint(AsaColors.coffeeBrown)
                    
                    // プリセットボタン
                    HStack(spacing: 8) {
                        ForEach(SearchRadius.allCases, id: \.id) { radius in
                            Button(radius.displayName) {
                                searchFilter.searchRadius = radius.rawValue
                            }
                            .buttonStyle(FilterChipButtonStyle(
                                isSelected: abs(searchFilter.searchRadius - radius.rawValue) < 50
                            ))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Price Filter Section
    
    private var priceFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("料金フィルター")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            
            AsaCard {
                VStack(spacing: 16) {
                    // 時間料金
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("最大時間料金")
                                .font(.subheadline)
                                .foregroundColor(AsaColors.darkSlate)
                            Spacer()
                            if let maxRate = searchFilter.maxHourlyRate {
                                Text("¥\(maxRate)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AsaColors.coffeeBrown)
                                Button {
                                    searchFilter.maxHourlyRate = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AsaColors.mutedSage)
                                }
                            } else {
                                Text("制限なし")
                                    .font(.subheadline)
                                    .foregroundColor(AsaColors.mutedSage)
                            }
                        }
                        
                        if searchFilter.maxHourlyRate != nil {
                            Slider(
                                value: Binding(
                                    get: { Double(searchFilter.maxHourlyRate ?? 500) },
                                    set: { searchFilter.maxHourlyRate = Int($0) }
                                ),
                                in: 100...500,
                                step: 50
                            )
                            .tint(AsaColors.coffeeBrown)
                        }
                        
                        Toggle("時間料金制限を有効にする", isOn: Binding(
                            get: { searchFilter.maxHourlyRate != nil },
                            set: { enabled in
                                if enabled {
                                    searchFilter.maxHourlyRate = 300
                                } else {
                                    searchFilter.maxHourlyRate = nil
                                }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: AsaColors.coffeeBrown))
                    }
                    
                    Divider()
                    
                    // 日料金
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("最大日料金")
                                .font(.subheadline)
                                .foregroundColor(AsaColors.darkSlate)
                            Spacer()
                            if let maxRate = searchFilter.maxDailyRate {
                                Text("¥\(maxRate)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AsaColors.coffeeBrown)
                                Button {
                                    searchFilter.maxDailyRate = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AsaColors.mutedSage)
                                }
                            } else {
                                Text("制限なし")
                                    .font(.subheadline)
                                    .foregroundColor(AsaColors.mutedSage)
                            }
                        }
                        
                        if searchFilter.maxDailyRate != nil {
                            Slider(
                                value: Binding(
                                    get: { Double(searchFilter.maxDailyRate ?? 2500) },
                                    set: { searchFilter.maxDailyRate = Int($0) }
                                ),
                                in: 1000...5000,
                                step: 500
                            )
                            .tint(AsaColors.coffeeBrown)
                        }
                        
                        Toggle("日料金制限を有効にする", isOn: Binding(
                            get: { searchFilter.maxDailyRate != nil },
                            set: { enabled in
                                if enabled {
                                    searchFilter.maxDailyRate = 2500
                                } else {
                                    searchFilter.maxDailyRate = nil
                                }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: AsaColors.coffeeBrown))
                    }
                }
            }
        }
    }
    
    // MARK: - Amenities Section
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("必要な設備・サービス")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(ParkingAmenity.allCases, id: \.self) { amenity in
                    Button {
                        if searchFilter.requiredAmenities.contains(amenity) {
                            searchFilter.requiredAmenities.remove(amenity)
                        } else {
                            searchFilter.requiredAmenities.insert(amenity)
                        }
                    } label: {
                        HStack {
                            Image(systemName: amenity.icon)
                                .font(.system(size: 16))
                            Text(amenity.rawValue)
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            searchFilter.requiredAmenities.contains(amenity) 
                                ? AsaColors.coffeeBrown.opacity(0.2)
                                : AsaColors.cardBackground
                        )
                        .foregroundColor(
                            searchFilter.requiredAmenities.contains(amenity)
                                ? AsaColors.coffeeBrown
                                : AsaColors.darkSlate
                        )
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    searchFilter.requiredAmenities.contains(amenity)
                                        ? AsaColors.coffeeBrown
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Payment Methods Section
    
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支払い方法")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            
            Text("いずれかの方法で支払い可能な駐車場を検索")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    Button {
                        if searchFilter.paymentMethods.contains(method) {
                            searchFilter.paymentMethods.remove(method)
                        } else {
                            searchFilter.paymentMethods.insert(method)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: method.icon)
                                .font(.system(size: 20))
                            Text(method.rawValue)
                                .font(.caption2)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(
                            searchFilter.paymentMethods.contains(method)
                                ? AsaColors.coffeeBrown.opacity(0.2)
                                : AsaColors.cardBackground
                        )
                        .foregroundColor(
                            searchFilter.paymentMethods.contains(method)
                                ? AsaColors.coffeeBrown
                                : AsaColors.darkSlate
                        )
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    searchFilter.paymentMethods.contains(method)
                                        ? AsaColors.coffeeBrown
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Vehicle Restrictions Section
    
    private var vehicleRestrictionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("車両制限")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)
                Spacer()
                Button("設定") {
                    showingVehicleSettings = true
                }
                .font(.caption)
                .foregroundColor(AsaColors.coffeeBrown)
            }
            
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    if !searchFilter.hasVehicleRestrictions {
                        Text("制限なし")
                            .font(.subheadline)
                            .foregroundColor(AsaColors.mutedSage)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            if let height = searchFilter.vehicleHeight {
                                Text("高さ: \(Int(height))cm以下")
                            }
                            if let width = searchFilter.vehicleWidth {
                                Text("幅: \(Int(width))cm以下")
                            }
                            if let length = searchFilter.vehicleLength {
                                Text("長さ: \(Int(length))cm以下")
                            }
                            if let weight = searchFilter.vehicleWeight {
                                Text("重量: \(Int(weight))kg以下")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(AsaColors.darkSlate)
                    }
                    
                    if searchFilter.hasVehicleRestrictions {
                        Button("クリア") {
                            searchFilter.clearVehicleRestrictions()
                        }
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                    }
                }
            }
        }
        .sheet(isPresented: $showingVehicleSettings) {
            VehicleSettingsSheet(searchFilter: searchFilter)
        }
    }
    
    // MARK: - Other Options Section
    
    private var otherOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("その他のオプション")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            
            AsaCard {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("空きありのみ表示", isOn: $searchFilter.showOnlyAvailable)
                        .toggleStyle(SwitchToggleStyle(tint: AsaColors.coffeeBrown))
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("並び順")
                            .font(.subheadline)
                            .foregroundColor(AsaColors.darkSlate)
                        
                        Picker("並び順", selection: $searchFilter.sortBy) {
                            ForEach(SortOption.allCases) { option in
                                Label(option.rawValue, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Filters Section
    
    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("クイックフィルター")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                quickFilterButton("近距離のみ", icon: "location.circle") {
                    searchFilter.searchRadius = 500
                }
                
                quickFilterButton("格安料金", icon: "yensign.circle") {
                    searchFilter.maxHourlyRate = 200
                    searchFilter.maxDailyRate = 1500
                }
                
                quickFilterButton("空きあり", icon: "car.circle") {
                    searchFilter.showOnlyAvailable = true
                }
                
                quickFilterButton("屋根付き", icon: "building.2.crop.circle") {
                    searchFilter.requiredAmenities.insert(.roofed)
                }
            }
        }
    }
    
    private func quickFilterButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AsaColors.cardBackground)
            .foregroundColor(AsaColors.darkSlate)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return "\(Int(distance))m"
        }
    }
}

// MARK: - Vehicle Settings Sheet

struct VehicleSettingsSheet: View {
    @State var searchFilter: SearchFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("車両サイズを入力することで、駐車可能な駐車場のみを検索できます。")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        vehicleDimensionSlider(
                            title: "高さ",
                            value: Binding(
                                get: { searchFilter.vehicleHeight ?? 160 },
                                set: { searchFilter.vehicleHeight = $0 }
                            ),
                            range: 120...250,
                            unit: "cm",
                            isEnabled: Binding(
                                get: { searchFilter.vehicleHeight != nil },
                                set: { enabled in
                                    if enabled {
                                        searchFilter.vehicleHeight = 160
                                    } else {
                                        searchFilter.vehicleHeight = nil
                                    }
                                }
                            )
                        )
                        
                        vehicleDimensionSlider(
                            title: "幅",
                            value: Binding(
                                get: { searchFilter.vehicleWidth ?? 170 },
                                set: { searchFilter.vehicleWidth = $0 }
                            ),
                            range: 140...200,
                            unit: "cm",
                            isEnabled: Binding(
                                get: { searchFilter.vehicleWidth != nil },
                                set: { enabled in
                                    if enabled {
                                        searchFilter.vehicleWidth = 170
                                    } else {
                                        searchFilter.vehicleWidth = nil
                                    }
                                }
                            )
                        )
                        
                        vehicleDimensionSlider(
                            title: "長さ",
                            value: Binding(
                                get: { searchFilter.vehicleLength ?? 450 },
                                set: { searchFilter.vehicleLength = $0 }
                            ),
                            range: 300...600,
                            unit: "cm",
                            isEnabled: Binding(
                                get: { searchFilter.vehicleLength != nil },
                                set: { enabled in
                                    if enabled {
                                        searchFilter.vehicleLength = 450
                                    } else {
                                        searchFilter.vehicleLength = nil
                                    }
                                }
                            )
                        )
                        
                        vehicleDimensionSlider(
                            title: "重量",
                            value: Binding(
                                get: { searchFilter.vehicleWeight ?? 1500 },
                                set: { searchFilter.vehicleWeight = $0 }
                            ),
                            range: 800...3000,
                            unit: "kg",
                            isEnabled: Binding(
                                get: { searchFilter.vehicleWeight != nil },
                                set: { enabled in
                                    if enabled {
                                        searchFilter.vehicleWeight = 1500
                                    } else {
                                        searchFilter.vehicleWeight = nil
                                    }
                                }
                            )
                        )
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("車両設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func vehicleDimensionSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        unit: String,
        isEnabled: Binding<Bool>
    ) -> some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    if isEnabled.wrappedValue {
                        Text("\(Int(value.wrappedValue))\(unit)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
                
                Toggle("制限する", isOn: isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: AsaColors.coffeeBrown))
                
                if isEnabled.wrappedValue {
                    Slider(value: value, in: range, step: unit == "kg" ? 100 : 10)
                        .tint(AsaColors.coffeeBrown)
                }
            }
        }
    }
}

// MARK: - Filter Chip Button Style

struct FilterChipButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? AsaColors.coffeeBrown.opacity(0.2)
                    : AsaColors.cardBackground
            )
            .foregroundColor(
                isSelected
                    ? AsaColors.coffeeBrown
                    : AsaColors.darkSlate
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                            ? AsaColors.coffeeBrown
                            : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}