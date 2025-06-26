//
//  SleepLogRow.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

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
    let sampleLog = SleepLog(
        date: Date(),
        bedTime: Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date(),
        wakeTime: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date(),
        quality: .good,
        notes: "よく眠れました"
    )
    
    SleepLogRow(log: sampleLog)
        .padding()
}