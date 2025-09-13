//
//  ContentView.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import SwiftUI

struct ContentView: View {
    @State private var stockViewModel = StockViewModel()
    @State private var watchListViewModel = WatchListViewModel()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ウォッチリストタブ
            NavigationStack {
                StockListView()
                    .environment(stockViewModel)
                    .environment(watchListViewModel)
                    .navigationTitle("ウォッチリスト")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
            }
            .tabItem {
                Label("ウォッチリスト", systemImage: "star.fill")
            }
            .tag(0)
            
            // 検索タブ
            NavigationStack {
                SearchView()
                    .environment(stockViewModel)
                    .environment(watchListViewModel)
                    .navigationTitle("銘柄検索")
            }
            .tabItem {
                Label("検索", systemImage: "magnifyingglass")
            }
            .tag(1)
            
            // マーケットタブ
            NavigationStack {
                MarketOverviewView()
                    .environment(stockViewModel)
                    .navigationTitle("マーケット")
            }
            .tabItem {
                Label("マーケット", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(2)
        }
        .tint(Color(red: 0.776, green: 0.549, blue: 0.325))  // AsaCoffeeBrown
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(watchListViewModel)
        }
        .onAppear {
            setupAppearance()
            loadInitialData()
        }
    }
    
    private func setupAppearance() {
        // タブバーの外観設定
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func loadInitialData() {
        // 初回起動時にデモデータを読み込む
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isFirstLaunch)
        if isFirstLaunch {
            watchListViewModel.loadDemoData()
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.isFirstLaunch)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}