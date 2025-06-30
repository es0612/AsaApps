//
//  WorkoutStatsView.swift
//  AsaWorkoutLog
//  
//  Created on 2025/07/01
//

import SwiftUI

struct WorkoutStatsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 全体統計カード
                OverallStatsView(viewModel: viewModel)
                
                // 今月の統計カード
                MonthlyStatsView(viewModel: viewModel)
                
                // 運動種類別統計
                WorkoutTypeStatsView(viewModel: viewModel)
                
                // 強度別統計
                IntensityStatsView(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("統計")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OverallStatsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var body: some View {
        AsaCard(backgroundColor: Color("AsaCoffeeBrown").opacity(0.1)) {
            VStack(alignment: .leading, spacing: 16) {
                Text("全体統計")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCardView(
                        title: "総運動回数",
                        value: "\(viewModel.totalWorkoutSessions)",
                        unit: "回",
                        color: Color("AsaCoffeeBrown")
                    )
                    
                    StatCardView(
                        title: "総運動時間",
                        value: formatTotalMinutes(viewModel.totalWorkoutMinutes),
                        unit: "",
                        color: Color("AsaMutedSage")
                    )
                    
                    StatCardView(
                        title: "平均運動時間",
                        value: "\(viewModel.averageSessionDuration)",
                        unit: "分",
                        color: Color("AsaMocha")
                    )
                    
                    if let mostCommon = viewModel.mostCommonWorkoutType {
                        StatCardView(
                            title: "よくする運動",
                            value: mostCommon.displayName,
                            unit: mostCommon.emoji,
                            color: Color(mostCommon.color)
                        )
                    }
                }
            }
        }
    }
    
    private func formatTotalMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return "\(days)日\(remainingHours)時間"
        } else if hours > 0 {
            return "\(hours)時間\(remainingMinutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

struct MonthlyStatsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var body: some View {
        AsaCard(backgroundColor: Color("AsaMutedSage").opacity(0.1)) {
            VStack(alignment: .leading, spacing: 16) {
                Text("今月の統計")
                    .font(.headline)
                    .foregroundColor(Color("AsaMutedSage"))
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCardView(
                        title: "今月の運動回数",
                        value: "\(viewModel.thisMonthSessions.count)",
                        unit: "回",
                        color: Color("AsaMutedSage")
                    )
                    
                    StatCardView(
                        title: "今月の運動時間",
                        value: "\(viewModel.thisMonthTotalMinutes)",
                        unit: "分",
                        color: Color("AsaCoffeeBrown")
                    )
                }
            }
        }
    }
}

struct WorkoutTypeStatsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var workoutTypeCounts: [(WorkoutType, Int)] {
        let typeCounts = Dictionary(grouping: viewModel.workoutSessions, by: { $0.workoutType })
            .mapValues { $0.count }
        
        return typeCounts.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("運動種類別統計")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                if workoutTypeCounts.isEmpty {
                    Text("まだ運動記録がありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                } else {
                    ForEach(workoutTypeCounts.prefix(5), id: \.0) { type, count in
                        HStack {
                            HStack(spacing: 8) {
                                Text(type.emoji)
                                    .font(.title3)
                                Text(type.displayName)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Text("\(count)回")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(type.color))
                        }
                        .padding(.vertical, 4)
                        
                        if type != workoutTypeCounts.prefix(5).last?.0 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

struct IntensityStatsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var intensityCounts: [(WorkoutIntensity, Int)] {
        let intensityCounts = Dictionary(grouping: viewModel.workoutSessions, by: { $0.intensity })
            .mapValues { $0.count }
        
        return WorkoutIntensity.allCases.compactMap { intensity in
            if let count = intensityCounts[intensity], count > 0 {
                return (intensity, count)
            }
            return nil
        }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("強度別統計")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                if intensityCounts.isEmpty {
                    Text("まだ運動記録がありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                } else {
                    ForEach(intensityCounts, id: \.0) { intensity, count in
                        HStack {
                            HStack(spacing: 8) {
                                Text(intensity.emoji)
                                    .font(.title3)
                                Text(intensity.displayName)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Text("\(count)回")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(intensity.color))
                        }
                        .padding(.vertical, 4)
                        
                        if intensity != intensityCounts.last?.0 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        WorkoutStatsView(viewModel: WorkoutViewModel())
    }
}