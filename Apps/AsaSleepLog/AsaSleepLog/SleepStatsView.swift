//
//  SleepStatsView.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct SleepStatsView: View {
    @ObservedObject var viewModel: SleepLogViewModel
    @State private var selectedPeriod: StatsPeriod = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択
                    Picker("期間", selection: $selectedPeriod) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // 総合統計カード
                    OverallStatsCard(viewModel: viewModel, period: selectedPeriod)
                        .padding(.horizontal)
                    
                    // 睡眠時間トレンドグラフ
                    SleepDurationChart(viewModel: viewModel, period: selectedPeriod)
                        .padding(.horizontal)
                    
                    // 睡眠の質トレンドグラフ
                    SleepQualityChart(viewModel: viewModel, period: selectedPeriod)
                        .padding(.horizontal)
                    
                    // 睡眠効率グラフ
                    SleepEfficiencyChart(viewModel: viewModel, period: selectedPeriod)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("睡眠統計")
            .background(Color("AsaSoftCream").opacity(0.3))
        }
    }
}

struct OverallStatsCard: View {
    @ObservedObject var viewModel: SleepLogViewModel
    let period: StatsPeriod
    
    var body: some View {
        AsaCard {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title2)
                    Text("\(period.displayName)の統計")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    StatItem(
                        title: "平均睡眠時間",
                        value: viewModel.averageSleepDurationFormatted,
                        icon: "moon.fill"
                    )
                    
                    StatItem(
                        title: "平均睡眠効率",
                        value: String(format: "%.1f%%", viewModel.averageSleepEfficiency),
                        icon: "percent"
                    )
                    
                    StatItem(
                        title: "目標達成率",
                        value: String(format: "%.0f%%", viewModel.goalAchievementRate(for: period)),
                        icon: "target"
                    )
                    
                    StatItem(
                        title: "平均睡眠の質",
                        value: String(format: "%.1f/5", viewModel.averageQualityScore),
                        icon: "star.fill"
                    )
                }
            }
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .font(.title3)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct SleepDurationChart: View {
    @ObservedObject var viewModel: SleepLogViewModel
    let period: StatsPeriod
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("睡眠時間の推移")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                }
                
                let logs = viewModel.sleepLogsForPeriod(period)
                if !logs.isEmpty {
                    SleepDurationBarChart(logs: logs)
                        .frame(height: 150)
                } else {
                    Text("データがありません")
                        .foregroundColor(.gray)
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct SleepDurationBarChart: View {
    let logs: [SleepLog]
    
    var body: some View {
        let maxDuration = logs.map(\.sleepDuration).max() ?? 1
        
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(logs.prefix(7), id: \.id) { log in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color("AsaCoffeeBrown"))
                        .frame(width: 30, height: CGFloat(log.sleepDuration / maxDuration) * 120)
                        .cornerRadius(4)
                    
                    Text("\(Int(log.sleepDuration / 3600))h")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(log.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SleepQualityChart: View {
    @ObservedObject var viewModel: SleepLogViewModel
    let period: StatsPeriod
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("睡眠の質の推移")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                }
                
                let logs = viewModel.sleepLogsForPeriod(period)
                if !logs.isEmpty {
                    SleepQualityBarChart(logs: logs)
                        .frame(height: 150)
                } else {
                    Text("データがありません")
                        .foregroundColor(.gray)
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct SleepQualityBarChart: View {
    let logs: [SleepLog]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(logs.prefix(7), id: \.id) { log in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color(log.quality.color))
                        .frame(width: 30, height: CGFloat(log.qualityScore) * 24)
                        .cornerRadius(4)
                    
                    Text(log.quality.emoji)
                        .font(.caption)
                    
                    Text(log.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SleepEfficiencyChart: View {
    @ObservedObject var viewModel: SleepLogViewModel
    let period: StatsPeriod
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("睡眠効率の推移")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                }
                
                let logs = viewModel.sleepLogsForPeriod(period)
                if !logs.isEmpty {
                    SleepEfficiencyBarChart(logs: logs)
                        .frame(height: 150)
                } else {
                    Text("データがありません")
                        .foregroundColor(.gray)
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct SleepEfficiencyBarChart: View {
    let logs: [SleepLog]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(logs.prefix(7), id: \.id) { log in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(log.sleepEfficiency >= 85 ? Color("AsaCoffeeBrown") : Color("AsaMutedSage"))
                        .frame(width: 30, height: CGFloat(log.sleepEfficiency / 100) * 120)
                        .cornerRadius(4)
                    
                    Text("\(Int(log.sleepEfficiency))%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(log.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SleepStatsView(viewModel: SleepLogViewModel())
}