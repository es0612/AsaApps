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
    
    var body: some View {
        NavigationView {
            VStack {
                if history.isEmpty {
                    Text("履歴がありません")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .padding()
                } else {
                    List {
                        ForEach(history) { record in
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
                    }
                }
            }
            .navigationTitle("タイマー履歴")
            .background( Color("AsaDarkSlate").opacity(0.8))
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
        TimerRecord(duration: 300, endTime: Date(), repeatCount: 2),
    ]))
}
