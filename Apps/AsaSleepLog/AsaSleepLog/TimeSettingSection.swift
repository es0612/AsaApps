//
//  TimeSettingSection.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct TimeSettingSection: View {
    @Binding var bedTime: Date
    @Binding var wakeTime: Date
    
    var body: some View {
        AsaCard {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("睡眠時間")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                }
                
                // 就寝時間
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(Color("AsaMutedSage"))
                            .font(.caption)
                        Text("就寝時間")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    DatePicker("", selection: $bedTime, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                }
                
                Divider()
                
                // 起床時間
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .font(.caption)
                        Text("起床時間")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    DatePicker("", selection: $wakeTime, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                }
                
                // 睡眠時間表示
                if wakeTime > bedTime {
                    HStack {
                        Text("睡眠時間:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(calculateSleepDuration())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
    
    private func calculateSleepDuration() -> String {
        let duration = wakeTime.timeIntervalSince(bedTime)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)時間\(minutes)分"
    }
}

#Preview {
    TimeSettingSection(bedTime: .constant(Date()), wakeTime: .constant(Date().addingTimeInterval(28800)))
        .padding()
}