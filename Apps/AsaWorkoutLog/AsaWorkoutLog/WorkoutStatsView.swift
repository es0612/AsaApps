//
//  WorkoutStatsView.swift
//  AsaWorkoutLog
//
//  Created on 2025/07/03
//

import SwiftUI

struct WorkoutStatsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 総合統計
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("総合統計")
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                StatCard(title: "総ワークアウト", value: "\(viewModel.totalWorkouts)", unit: "回")
                                StatCard(title: "総運動時間", value: "\(Int(viewModel.totalDuration / 60))", unit: "分")
                                StatCard(title: "平均運動時間", value: "\(Int(viewModel.averageWorkoutDuration / 60))", unit: "分")
                                StatCard(title: "今週の運動", value: "\(viewModel.thisWeekWorkouts.count)", unit: "回")
                            }
                        }
                        .padding()
                    }
                    
                    // 週間進捗
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("今週の進捗")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                
                                Spacer()
                                
                                Text("\(Int(viewModel.weeklyProgress * 100))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(viewModel.weeklyProgress >= 1.0 ? .green : Color("AsaCoffeeBrown"))
                            }
                            
                            ProgressView(value: viewModel.weeklyProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .scaleEffect(x: 1, y: 3, anchor: .center)
                            
                            HStack {
                                Text("達成: \(Int(viewModel.thisWeekDuration / 60))分")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("目標: \(Int(viewModel.weeklyGoal / 60))分")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                    
                    // カテゴリ別統計
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("カテゴリ別統計")
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            let categoryStats = viewModel.workoutsByCategory()
                            
                            if categoryStats.isEmpty {
                                Text("まだデータがありません")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(WorkoutCategory.allCases, id: \.self) { category in
                                    if let workouts = categoryStats[category], !workouts.isEmpty {
                                        CategoryStatRow(
                                            category: category,
                                            workouts: workouts,
                                            totalWorkouts: viewModel.totalWorkouts
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // 最近の活動
                    if !viewModel.workouts.isEmpty {
                        AsaCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("最近の活動")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                
                                ForEach(viewModel.workouts.sorted(by: { $0.date > $1.date }).prefix(5)) { workout in
                                    RecentActivityRow(workout: workout)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CategoryStatRow: View {
    let category: WorkoutCategory
    let workouts: [Workout]
    let totalWorkouts: Int
    
    private var totalDuration: TimeInterval {
        workouts.reduce(0) { $0 + $1.duration }
    }
    
    private var percentage: Double {
        guard totalWorkouts > 0 else { return 0 }
        return Double(workouts.count) / Double(totalWorkouts)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .frame(width: 20)
                
                Text(category.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(workouts.count)回")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("\(Int(totalDuration / 60))分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .padding(.vertical, 4)
    }
}

struct RecentActivityRow: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            Image(systemName: workout.category.icon)
                .foregroundColor(workout.category.color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(formatDate(workout.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(workout.formattedDuration)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
        .padding(.vertical, 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    WorkoutStatsView(viewModel: WorkoutViewModel())
}