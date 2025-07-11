//
//  ContentView.swift
//  AsaLocationTracker
//  
//  Created on 2025/07/12
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LocationData.timestamp, order: .reverse) private var savedLocations: [LocationData]
    @StateObject private var viewModel = LocationViewModel()
    @State private var showingAddLocationSheet = false
    
    var body: some View {
        TabView {
            LocationListView(locations: savedLocations, onDelete: deleteLocation)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("位置リスト")
                }
            
            LocationMapView(locations: savedLocations)
                .tabItem {
                    Image(systemName: "map")
                    Text("マップ")
                }
            
            AddLocationView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("位置追加")
                }
        }
        .accentColor(Color("AsaCoffeeBrown"))
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
    
    private func deleteLocation(_ location: LocationData) {
        withAnimation {
            modelContext.delete(location)
        }
    }
}

struct LocationListView: View {
    let locations: [LocationData]
    let onDelete: (LocationData) -> Void
    
    var body: some View {
        NavigationView {
            List(locations) { location in
                LocationRowView(location: location)
                    .swipeActions(edge: .trailing) {
                        Button("削除", role: .destructive) {
                            onDelete(location)
                        }
                    }
            }
            .navigationTitle("保存した位置")
        }
    }
}

struct LocationRowView: View {
    let location: LocationData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(location.name)
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            Text("緯度: \(location.latitude, specifier: "%.6f"), 経度: \(location.longitude, specifier: "%.6f")")
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
            Text(location.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color("AsaSoftCream").opacity(0.1))
        .cornerRadius(8)
    }
}

struct AddLocationView: View {
    @ObservedObject var viewModel: LocationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("新しい位置を追加")
                    .font(.title)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .padding()
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color("AsaSoftCream").opacity(0.3))
                        .cornerRadius(10)
                }
                
                VStack(spacing: 16) {
                    TextField("位置の名前", text: $viewModel.locationName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    if !viewModel.isLocationEnabled {
                        AsaButton(
                            title: "位置情報の許可を求める",
                            action: { viewModel.requestLocationPermission() },
                            color: Color("AsaCoffeeBrown")
                        )
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            AsaButton(
                                title: "現在の位置を取得",
                                action: { viewModel.getCurrentLocation() },
                                color: Color("AsaMocha")
                            )
                            .padding(.horizontal)
                            
                            AsaButton(
                                title: "位置を保存",
                                action: { viewModel.saveCurrentLocation() },
                                color: Color("AsaCoffeeBrown"),
                                isEnabled: !viewModel.locationName.isEmpty
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("位置を追加")
            .background(Color("AsaSoftCream").opacity(0.1))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: LocationData.self, inMemory: true)
}
