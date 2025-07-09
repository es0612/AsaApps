//
//  ContentView.swift
//  AsaWeather
//  
//  Created on 2025/07/05
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var viewModel: WeatherViewModel?
    @State private var showingLocationPermission = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color("AsaSoftCream").opacity(0.3),
                        Color("AsaDarkSlate").opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showingLocationPermission {
                    LocationPermissionView(
                        locationManager: locationManager,
                        onPermissionGranted: {
                            print("🌤️ ContentView: Location permission granted")
                            showingLocationPermission = false
                            // ViewModelの初期化で既にloadWeatherDataが実行されるため、ここでは呼び出さない
                        }
                    )
                } else {
                    if let viewModel = viewModel {
                        ScrollView {
                            VStack(spacing: 20) {
                                // 検索バー
                                SearchBar(searchText: $searchText) { cityName in
                                    Task {
                                        await viewModel.searchWeather(for: cityName)
                                        searchText = ""
                                    }
                                }
                                .padding(.horizontal)
                                
                                if viewModel.isLoading {
                                    ProgressView("天気情報を取得中...")
                                        .font(.body)
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                        .padding()
                                        .onAppear {
                                            print("🌤️ ContentView: Showing loading state - isLoading: \(viewModel.isLoading), currentWeather: \(viewModel.currentWeather?.name ?? "nil")")
                                        }
                                } else if let weather = viewModel.currentWeather {
                                    // 現在の天気
                                    WeatherCard(weather: weather)
                                        .padding(.horizontal)
                                        .onAppear {
                                            print("🌤️ ContentView: Showing weather data for \(weather.name)")
                                        }
                                    
                                    // 5日間予報
                                    if !viewModel.dailyForecast.isEmpty {
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("5日間予報")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(Color("AsaCoffeeBrown"))
                                                .padding(.horizontal)
                                            
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 12) {
                                                    ForEach(viewModel.dailyForecast) { forecast in
                                                        ForecastCard(forecast: forecast)
                                                    }
                                                }
                                                .padding(.horizontal)
                                            }
                                        }
                                    }
                                } else if let errorMessage = viewModel.errorMessage {
                                    VStack(spacing: 16) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 40))
                                            .foregroundColor(Color("AsaCoffeeBrown"))
                                        
                                        Text("エラー")
                                            .font(.headline)
                                            .foregroundColor(Color("AsaCoffeeBrown"))
                                        
                                        Text(errorMessage)
                                            .font(.body)
                                            .foregroundColor(Color("AsaMutedSage"))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                        
                                        Button("再試行") {
                                            Task {
                                                await viewModel.refreshWeather()
                                            }
                                        }
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color("AsaCoffeeBrown"))
                                        .cornerRadius(10)
                                    }
                                    .padding()
                                } else {
                                    // デバッグ用：どの条件にも当てはまらない場合
                                    Text("データなし")
                                        .onAppear {
                                            print("🌤️ ContentView: No data state - isLoading: \(viewModel.isLoading), currentWeather: \(viewModel.currentWeather?.name ?? "nil"), errorMessage: \(viewModel.errorMessage ?? "nil")")
                                        }
                                }
                            }
                            .padding(.vertical)
                        }
                        .refreshable {
                            await viewModel.refreshWeather()
                        }
                    } else {
                        ProgressView("初期化中...")
                            .font(.body)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .navigationTitle("AsaWeather")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if !locationManager.isLocationEnabled {
                            showingLocationPermission = true
                        } else if let viewModel = viewModel {
                            Task {
                                await viewModel.refreshWeather()
                            }
                        }
                    }) {
                        Image(systemName: locationManager.isLocationEnabled ? "location.fill" : "location")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = WeatherViewModel(locationManager: locationManager)
            }
            if locationManager.authorizationStatus == .notDetermined {
                showingLocationPermission = true
            }
        }
        .alert("位置情報エラー", isPresented: .constant(locationManager.errorMessage != nil && !showingLocationPermission)) {
            Button("OK") {
                locationManager.errorMessage = nil
            }
        } message: {
            Text(locationManager.errorMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
}
