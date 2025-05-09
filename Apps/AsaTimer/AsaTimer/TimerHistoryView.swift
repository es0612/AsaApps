//
//  TimerHistoryView.swift
//  AsaTimer
//
//  Created on 2025/05/09
//

import SwiftUI

struct TimerHistoryView: View {
    let history: [TimerRecord]
    
    var body: some View {
        NavigationView {
            List(history) { record in
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
                        }
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
            }
//            .listStyle(.plain) // シンプルなリストスタイル
            .navigationTitle("タイマー履歴")
            .background( Color("AsaDarkSlate").opacity(0.8))
        }
    }
}

#Preview {
    TimerHistoryView(history: [
        TimerRecord(duration: 120, endTime: Date()),
        TimerRecord(duration: 300, endTime: Date())
    ])
}
