//
//  TimerHistoryView.swift
//  AsaTimer
//
//  Created on 2025/05/09
//

import SwiftUI

struct TimerHistoryView: View {
    @Binding var history: [TimerRecord]
    @State private var showClearAlert = false // 削除確認アラート
    
    @State private var filterOption: FilterOption = .all
    @State private var sortOption: SortOption = .endTime
    
    enum FilterOption: String, CaseIterable {
        case all = "すべて"
        case long = "5分以上"
    }
    
    enum SortOption: String, CaseIterable {
        case endTime = "終了時間順"
        case duration = "タイマー時間順"
    }
    
    var filteredHistory: [TimerRecord] {
        history.filter { record in
            switch filterOption {
            case .all:
                return true
            case .long:
                return record.duration >= 300
            }
        }
    }
    
    var sortedHistory: [TimerRecord] {
        filteredHistory.sorted { a, b in
            switch sortOption {
            case .endTime:
                return a.endTime > b.endTime
            case .duration:
                return a.duration > b.duration
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if history.isEmpty {
                    Text("履歴がありません")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .padding()
                } else {
                    Picker("フィルター", selection: $filterOption) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    Picker("並べ替え", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    List {
                        ForEach(sortedHistory) { record in
                            NavigationLink(destination: TimerDetailView(record: record)) {
                                HStack {
                                    Image("AsaLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                    VStack(alignment: .leading) {
                                        Text(record.formattedDuration)
                                            .font(.title3)
                                            .foregroundColor(Color("AsaCoffeeBrown"))
                                        Text(record.formattedEndTime)
                                            .font(.caption)
                                            .foregroundColor(Color("AsaMocha"))
                                        if record.repeatCount > 1 {
                                            Text("繰り返し: \(record.repeatCount)回")
                                                .font(.caption)
                                                .foregroundColor(Color("AsaMutedSage"))
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 5)
                            }
                            
                        }
                        .onDelete(perform: { indexSet in
                            withAnimation(.easeInOut) {
                                history.remove(atOffsets: indexSet)
                            }
                        })
                        .onMove { source, destination in
                            history.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                }
            }
            .navigationTitle("タイマー履歴")
            //            .background( Color("AsaSoftCream").opacity(0.8))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showClearAlert = true
                    }) {
                        Text("すべて削除")
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    .disabled(history.isEmpty)
                }
            }
            .alert("履歴をすべて削除しますか？", isPresented: $showClearAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    history.removeAll()
                }
            }
        }
    }
}

#Preview {
    TimerHistoryView(history: .constant([
        TimerRecord(duration: 120, endTime: Date()),
        TimerRecord(duration: 300, endTime: Date().addingTimeInterval(100), repeatCount: 2),
        TimerRecord(duration: 400, endTime: Date().addingTimeInterval(10), repeatCount: 2),
    ]))
}
