//
//  ContentView.swift
//  AsaWorkoutLog
//
//  Created on 2025/07/03
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var showingAddWorkout = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム画面
            HomeView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)
            
            // 履歴画面
            WorkoutHistoryView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("履歴")
                }
                .tag(1)
            
            // 統計画面
            WorkoutStatsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("統計")
                }
                .tag(2)
            
            // 目標設定画面
            WorkoutGoalsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "target")
                    Text("目標")
                }
                .tag(3)
        }
        .sheet(isPresented: $showingAddWorkout) {
            AddWorkoutView(viewModel: viewModel)
        }
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var showingAddWorkout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    VStack(spacing: 8) {
                        Text("🏃‍♂️")
                            .font(.system(size: 50))
                        
                        Text("今週の進捗")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    .padding(.top)
                    
                    // 週間進捗
                    AsaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("今週の運動時間")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Spacer()
                                Text("\(Int(viewModel.thisWeekDuration / 60))分")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            ProgressView(value: viewModel.weeklyProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                            
                            HStack {
                                Text("目標: \(Int(viewModel.weeklyGoal / 60))分")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(viewModel.weeklyProgress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(viewModel.weeklyProgress >= 1.0 ? .green : Color("AsaCoffeeBrown"))
                            }
                        }
                        .padding()
                    }
                    
                    // 今週のワークアウト
                    AsaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("今週のワークアウト")
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            if viewModel.thisWeekWorkouts.isEmpty {
                                Text("まだワークアウトがありません")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(viewModel.thisWeekWorkouts.prefix(3)) { workout in
                                    WorkoutRowView(workout: workout)
                                }
                                
                                if viewModel.thisWeekWorkouts.count > 3 {
                                    Text("他 \(viewModel.thisWeekWorkouts.count - 3)件")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // クイック統計
                    AsaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("クイック統計")
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            HStack {
                                StatView(title: "総ワークアウト", value: "\(viewModel.totalWorkouts)回")
                                Spacer()
                                StatView(title: "総時間", value: "\(Int(viewModel.totalDuration / 60))分")
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("ワークアウトログ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddWorkout = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddWorkout) {
            AddWorkoutView(viewModel: viewModel)
        }
    }
}

struct WorkoutRowView: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            Image(systemName: workout.category.icon)
                .foregroundColor(workout.category.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(workout.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(workout.formattedDuration)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
        .padding(.vertical, 4)
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
    }
}

#Preview {
    ContentView()
}