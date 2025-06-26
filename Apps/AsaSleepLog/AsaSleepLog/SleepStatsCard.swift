//
//  SleepStatsCard.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct SleepStatsCard: View {
    let totalLogs: Int
    let averageDuration: String
    
    var body: some View {
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
                        Text("\(totalLogs)回")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("平均睡眠時間")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(averageDuration)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

#Preview {
    SleepStatsCard(totalLogs: 5, averageDuration: "7時間30分")
        .padding()
}