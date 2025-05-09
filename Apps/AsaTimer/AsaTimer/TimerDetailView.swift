//
//  TimerDetailView.swift
//  AsaTimer
//
//  Created on 2025/05/09
//

import SwiftUI

struct TimerDetailView: View {
    let record: TimerRecord
    
    var body: some View {
        ZStack {
            Color("AsaSoftCream").opacity(0.1)
                .ignoresSafeArea()
            Color("AsaDarkSlate").opacity(0.8)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image("AsaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .shadow(radius: 2)
                Text("タイマー詳細")
                    .font(.title)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                Text("時間: \(record.formattedDuration)")
                    .font(.title2)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .padding()
                    .background(Color("AsaSoftCream").opacity(0.3))
                    .cornerRadius(8)
                Text("終了時刻: \(record.formattedEndTime)")
                    .font(.subheadline)
                    .foregroundColor(Color("AsaMocha"))
                Spacer()
            }
            .padding()
        }
        .navigationTitle("履歴詳細")
    }
}

#Preview {
    TimerDetailView(record: TimerRecord(duration: 120, endTime: Date()))
}
