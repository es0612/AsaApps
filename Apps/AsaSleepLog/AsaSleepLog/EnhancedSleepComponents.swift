//
//  EnhancedSleepComponents.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct EnhancedStatsCard: View {
    @ObservedObject var viewModel: SleepLogViewModel
    
    var body: some View {
        AsaCard {
            VStack(spacing: 15) {
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
                
                // 基本統計
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    StatCard(
                        title: "総記録数",
                        value: "\(viewModel.sleepLogs.count)回",
                        icon: "number",
                        color: "AsaCoffeeBrown"
                    )
                    
                    StatCard(
                        title: "平均睡眠時間",
                        value: viewModel.averageSleepDurationFormatted,
                        icon: "moon.fill",
                        color: "AsaCoffeeBrown"
                    )
                    
                    StatCard(
                        title: "平均睡眠効率",
                        value: String(format: "%.1f%%", viewModel.averageSleepEfficiency),
                        icon: "speedometer",
                        color: viewModel.averageSleepEfficiency >= 85 ? "AsaCoffeeBrown" : "AsaMutedSage"
                    )
                    
                    StatCard(
                        title: "目標達成率",
                        value: String(format: "%.0f%%", viewModel.goalAchievementRate()),
                        icon: "target",
                        color: viewModel.goalAchievementRate() >= 70 ? "AsaCoffeeBrown" : "AsaMutedSage"
                    )
                }
                
                // 今週のトレンド
                if !viewModel.sleepLogsForPeriod(.week).isEmpty {
                    Divider()
                    
                    VStack(spacing: 10) {
                        HStack {
                            Text("今週のトレンド")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Spacer()
                        }
                        
                        WeeklyTrendView(viewModel: viewModel)
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(color))
                .font(.title3)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color(color))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
    }
}

struct WeeklyTrendView: View {
    @ObservedObject var viewModel: SleepLogViewModel
    
    var body: some View {
        let weeklyLogs = viewModel.sleepLogsForPeriod(.week)
        let maxDuration = weeklyLogs.map(\.sleepDuration).max() ?? 1
        
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(weeklyLogs.prefix(7), id: \.id) { log in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color("AsaCoffeeBrown"))
                        .frame(width: 20, height: CGFloat(log.sleepDuration / maxDuration) * 40)
                        .cornerRadius(2)
                    
                    Text(log.date, format: .dateTime.weekday(.abbreviated))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct EnhancedSleepLogRow: View {
    let log: SleepLog
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー行
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.date, style: .date)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        if let mood = log.mood {
                            HStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.caption)
                                Text(mood.displayName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(log.quality.emoji)
                                .font(.title3)
                            Text(log.quality.displayName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text(log.sleepDurationFormatted)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                // 詳細情報
                VStack(spacing: 8) {
                    // 時間情報
                    HStack {
                        TimeInfoRow(
                            icon: "moon.fill",
                            title: "就寝",
                            time: log.bedTime,
                            color: "AsaMutedSage"
                        )
                        
                        Spacer()
                        
                        TimeInfoRow(
                            icon: "sun.max.fill", 
                            title: "起床",
                            time: log.wakeTime,
                            color: "AsaCoffeeBrown"
                        )
                    }
                    
                    // 睡眠効率とその他
                    HStack {
                        SleepMetric(
                            title: "睡眠効率",
                            value: log.sleepEfficiencyFormatted,
                            icon: "speedometer",
                            isGood: log.sleepEfficiency >= 85
                        )
                        
                        Spacer()
                        
                        if log.wakeUpCount > 0 {
                            SleepMetric(
                                title: "夜中覚醒",
                                value: "\(log.wakeUpCount)回",
                                icon: "eye",
                                isGood: log.wakeUpCount <= 1
                            )
                        }
                    }
                }
                
                // メモ
                if let notes = log.notes, !notes.isEmpty {
                    Divider()
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .italic()
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

struct TimeInfoRow: View {
    let icon: String
    let title: String
    let time: Date
    let color: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(Color(color))
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(time, formatter: timeFormatter)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
}

struct SleepMetric: View {
    let title: String
    let value: String
    let icon: String
    let isGood: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(isGood ? Color("AsaCoffeeBrown") : Color("AsaMutedSage"))
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isGood ? Color("AsaCoffeeBrown") : Color("AsaMutedSage"))
            }
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    VStack {
        EnhancedStatsCard(viewModel: SleepLogViewModel())
            .padding()
        
        EnhancedSleepLogRow(log: SleepLog(
            date: Date(),
            bedTime: Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date(),
            wakeTime: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date(),
            quality: .good,
            notes: "よく眠れました",
            wakeUpCount: 1,
            mood: .happy
        ))
        .padding()
    }
}