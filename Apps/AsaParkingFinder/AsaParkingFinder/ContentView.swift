//
//  ContentView.swift
//  AsaParkingFinder
//
//  駐車場検索アプリのメインビュー
//

import SwiftUI
import AsaUIKit

struct ContentView: View {
    @State private var viewModel = ParkingFinderViewModel()
    @State private var showingFilter = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                AsaColors.softCream.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 表示モード切り替えヘッダー
                    displayModeHeader
                    
                    // メインコンテンツ
                    if viewModel.displayMode == .list {
                        ParkingListView(viewModel: viewModel)
                    } else {
                        ParkingMapView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("駐車場検索")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
            }
            .onAppear {
                if !viewModel.hasSearched && viewModel.isLocationEnabled {
                    Task {
                        await viewModel.searchNearbyParkingLots()
                    }
                }
            }
            .alert("エラー", isPresented: $viewModel.showingErrorAlert) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
            }
            .sheet(isPresented: $showingFilter) {
                FilterSheet(searchFilter: viewModel.searchFilter) {
                    Task {
                        await viewModel.searchNearbyParkingLots()
                    }
                }
            }
        }
    }
    
    // MARK: - Display Mode Header
    
    private var displayModeHeader: some View {
        HStack {
            // 検索結果サマリー
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.searchResultSummary)
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)
                
                if viewModel.isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("検索中...")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
            }
            
            Spacer()
            
            // 表示モード切り替え
            Picker("表示モード", selection: $viewModel.displayMode) {
                ForEach(DisplayMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 140)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.8))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Toolbar Buttons
    
    private var toolbarButtons: some View {
        HStack(spacing: 12) {
            // 検索フィルターボタン
            Button {
                showingFilter = true
            } label: {
                Image(systemName: viewModel.searchFilter.hasActiveFilters ? "slider.horizontal.3.circle.fill" : "slider.horizontal.3")
                    .foregroundColor(viewModel.searchFilter.hasActiveFilters ? AsaColors.coffeeBrown : AsaColors.mutedSage)
            }
            
            // 位置情報更新ボタン
            Button {
                if viewModel.isLocationEnabled {
                    Task {
                        await viewModel.refreshSearch()
                    }
                } else {
                    viewModel.requestLocationPermission()
                }
            } label: {
                Image(systemName: viewModel.isLocationEnabled ? "location.circle.fill" : "location.circle")
                    .foregroundColor(viewModel.isLocationEnabled ? AsaColors.coffeeBrown : AsaColors.mutedSage)
            }
            .disabled(viewModel.isSearching)
        }
    }
}

// MARK: - Temporary Placeholder Views

struct ParkingListView: View {
    let viewModel: ParkingFinderViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredAndSortedParkingLots) { lot in
                    ParkingLotCardView(
                        lot: lot,
                        distance: viewModel.getDistanceString(to: lot),
                        onTap: { viewModel.selectParkingLot(lot) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .refreshable {
            await viewModel.refreshSearch()
        }
    }
}

// ParkingMapView は Views/ParkingMapView.swift で定義

struct ParkingLotCardView: View {
    let lot: ParkingLot
    let distance: String
    let onTap: () -> Void
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー行
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lot.name)
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)
                        
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(lot.displayRate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AsaColors.coffeeBrown)
                        
                        if let available = lot.availableSpaces {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(available > 0 ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text("\(available)台")
                                    .font(.caption)
                                    .foregroundColor(AsaColors.mutedSage)
                            }
                        }
                    }
                }
                
                // アメニティ表示
                if !lot.amenities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(lot.amenities.prefix(5), id: \.self) { amenity in
                                HStack(spacing: 4) {
                                    Image(systemName: amenity.icon)
                                        .font(.caption2)
                                    Text(amenity.rawValue)
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AsaColors.softCream)
                                .cornerRadius(8)
                                .foregroundColor(AsaColors.mutedSage)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                
                // 住所
                Text(lot.address)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                    .lineLimit(2)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    ContentView()
}