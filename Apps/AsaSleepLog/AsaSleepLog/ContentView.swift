//
//  ContentView.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SleepLogViewModel()
    @State private var showingAddLog = false
    @State private var showingStats = false
    @State private var showingGoals = false
    
    var body: some View {
        TabView {
            // メイン画面
            NavigationView {
                VStack(spacing: 20) {
                    // 拡張統計カード
                    EnhancedStatsCard(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // 記録一覧
                    List {
                        ForEach(viewModel.sleepLogs) { log in
                            EnhancedSleepLogRow(log: log)
                        }
                        .onDelete(perform: viewModel.deleteSleepLog)
                    }
                    .listStyle(PlainListStyle())
                    
                    // 記録追加ボタン
                    AsaButton(title: "睡眠記録を追加") {
                        showingAddLog = true
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .navigationTitle("睡眠ログ")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingGoals = true }) {
                            Image(systemName: "target")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                }
                .background(Color("AsaSoftCream").opacity(0.3))
                .sheet(isPresented: $showingAddLog) {
                    AddSleepLogView(viewModel: viewModel)
                }
                .sheet(isPresented: $showingGoals) {
                    SleepGoalsView(viewModel: viewModel)
                }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("ホーム")
            }
            
            // 統計画面
            SleepStatsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("統計")
                }
        }
        .accentColor(Color("AsaCoffeeBrown"))
    }
}


#Preview {
    ContentView()
}
