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
                AsaCard {
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "bed.double.fill")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                                .font(.title2)
                            Text("睡眠統計")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("総記録数")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(viewModel.sleepLogs.count)回")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("平均睡眠時間")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(viewModel.averageSleepDurationFormatted)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
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

struct SleepLogRow: View {
    let log: SleepLog
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(log.date, style: .date)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    Text(log.quality.emoji)
                        .font(.title2)
                    Text(log.quality.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(Color("AsaMutedSage"))
                                .font(.caption)
                            Text("就寝: \(log.bedTime, formatter: timeFormatter)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                                .font(.caption)
                            Text("起床: \(log.wakeTime, formatter: timeFormatter)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Text(log.sleepDurationFormatted)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                if let notes = log.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    ContentView()
}
