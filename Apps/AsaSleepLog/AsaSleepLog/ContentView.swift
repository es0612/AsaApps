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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 統計カード
                SleepStatsCard(
                    totalLogs: viewModel.sleepLogs.count,
                    averageDuration: viewModel.averageSleepDurationFormatted
                )
                .padding(.horizontal)
                
                // 記録一覧
                List {
                    ForEach(viewModel.sleepLogs) { log in
                        SleepLogRow(log: log)
                    }
                    .onDelete(perform: viewModel.deleteSleepLog)
                }
                .listStyle(PlainListStyle())
                
                Spacer()
                
                // 記録追加ボタン
                AsaButton(title: "睡眠記録を追加") {
                    showingAddLog = true
                }
                .padding(.horizontal)
            }
            .navigationTitle("睡眠ログ")
            .background(Color("AsaSoftCream").opacity(0.3))
            .sheet(isPresented: $showingAddLog) {
                AddSleepLogView(viewModel: viewModel)
            }
        }
    }
}


#Preview {
    ContentView()
}
