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
            if locations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 60))
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    Text("保存された位置がありません")
                        .font(.title2)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("「位置追加」タブから\n新しい位置を追加してください")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("AsaMutedSage"))
                }
                .navigationTitle("保存した位置")
            } else {
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
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color("AsaSoftCream").opacity(0.3))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    TextField("位置の名前", text: $viewModel.locationName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // デバッグ情報（開発中のみ表示）
                    #if DEBUG
                    VStack(alignment: .leading, spacing: 4) {
                        Text("デバッグ情報:")
                            .font(.caption2)
                            .foregroundColor(Color("AsaMutedSage"))
                        Text("許可状態: \(viewModel.authorizationStatus)")
                            .font(.caption2)
                        Text("位置情報利用可: \(viewModel.isLocationEnabled ? "はい" : "いいえ")")
                            .font(.caption2)
                        Text("現在位置: \(viewModel.hasCurrentLocation ? "取得済み" : "未取得")")
                            .font(.caption2)
                        Text("読み込み中: \(viewModel.isLoadingLocation ? "はい" : "いいえ")")
                            .font(.caption2)
                    }
                    .padding(.horizontal)
                    .foregroundColor(Color("AsaMutedSage"))
                    #endif
                    
                    if !viewModel.isLocationEnabled {
                        VStack(spacing: 12) {
                            if viewModel.authorizationStatus == "未決定" {
                                Text("位置情報の使用許可が必要です")
                                    .font(.callout)
                                    .foregroundColor(Color("AsaMutedSage"))
                                    .multilineTextAlignment(.center)
                                
                                #if DEBUG
                                Text("シミュレーター使用時は、デバイス > 位置情報 > カスタムの場所 で位置を設定してください")
                                    .font(.caption2)
                                    .foregroundColor(Color("AsaMutedSage"))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                #endif
                                
                                AsaButton(
                                    title: "位置情報の許可を求める",
                                    action: { viewModel.requestLocationPermission() },
                                    color: Color("AsaCoffeeBrown")
                                )
                            } else {
                                Text("位置情報へのアクセスが制限されています")
                                    .font(.callout)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                
                                Text("設定アプリから位置情報の許可を有効にしてください")
                                    .font(.caption)
                                    .foregroundColor(Color("AsaMutedSage"))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            if viewModel.isLoadingLocation {
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                                        .scaleEffect(1.2)
                                    Text("位置情報を取得中...")
                                        .font(.callout)
                                        .foregroundColor(Color("AsaMutedSage"))
                                }
                                .padding()
                            } else {
                                AsaButton(
                                    title: "現在の位置を取得",
                                    action: { viewModel.getCurrentLocation() },
                                    color: Color("AsaMocha")
                                )
                                .padding(.horizontal)
                            }
                            
                            AsaButton(
                                title: "位置を保存",
                                action: { viewModel.saveCurrentLocation() },
                                color: Color("AsaCoffeeBrown"),
                                isEnabled: !viewModel.locationName.isEmpty && !viewModel.isLoadingLocation
                            )
                            .padding(.horizontal)
                            
                            if viewModel.hasCurrentLocation {
                                VStack(spacing: 4) {
                                    Text("✓ 位置情報が取得されました")
                                        .font(.caption)
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                    Text("位置の名前を入力して保存してください")
                                        .font(.caption2)
                                        .foregroundColor(Color("AsaMutedSage"))
                                }
                                .padding(.top, 4)
                            } else if viewModel.isLocationEnabled {
                                Text("まず「現在の位置を取得」ボタンを押してください")
                                    .font(.caption2)
                                    .foregroundColor(Color("AsaMutedSage"))
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }
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
