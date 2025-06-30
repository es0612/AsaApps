//
//  ContentView.swift
//  AsaWorkoutLog
//  
//  Created on 2025/07/01
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 週間統計セクション
                    WeeklyStatsView(viewModel: viewModel)
                    
                    // クイックアクションセクション
                    QuickActionsView(viewModel: viewModel)
                    
                    // 最近のワークアウトセクション
                    RecentWorkoutsView(viewModel: viewModel)
                }
                .padding()
            }
            .navigationTitle("ワークアウトログ")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.isShowingAddSession) {
                AddWorkoutView(viewModel: viewModel)
            }
        }
    }
}

struct WeeklyStatsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var body: some View {
        AsaCard(backgroundColor: Color("AsaSoftCream").opacity(0.3)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title2)
                    Text("今週の目標")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    // 週間時間目標
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("運動時間")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(viewModel.thisWeekTotalMinutes)分 / \(viewModel.workoutGoal.weeklyTargetMinutes)分")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        ProgressView(value: viewModel.thisWeekProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                    
                    // 週間セッション数目標
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("セッション数")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(viewModel.thisWeekSessionCount)回 / \(viewModel.workoutGoal.weeklyTargetSessions)回")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        ProgressView(value: viewModel.thisWeekSessionProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaMutedSage")))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                }
            }
        }
    }
}

struct QuickActionsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            AsaButton(title: "運動を記録", action: {
                viewModel.showAddSession()
            })
            
            HStack(spacing: 12) {
                NavigationLink(destination: WorkoutHistoryView(viewModel: viewModel)) {
                    AsaCard(backgroundColor: Color("AsaMutedSage").opacity(0.2)) {
                        VStack {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                                .foregroundColor(Color("AsaMutedSage"))
                            Text("履歴")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: WorkoutStatsView(viewModel: viewModel)) {
                    AsaCard(backgroundColor: Color("AsaMocha").opacity(0.2)) {
                        VStack {
                            Image(systemName: "chart.pie")
                                .font(.title2)
                                .foregroundColor(Color("AsaMocha"))
                            Text("統計")
                                .font(.caption)
                                .foregroundColor(Color("AsaMocha"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: WorkoutGoalsView(viewModel: viewModel)) {
                    AsaCard(backgroundColor: Color("AsaCoffeeBrown").opacity(0.2)) {
                        VStack {
                            Image(systemName: "target")
                                .font(.title2)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Text("目標")
                                .font(.caption)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct RecentWorkoutsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title3)
                    Text("最近の運動")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                    if !viewModel.workoutSessions.isEmpty {
                        NavigationLink(destination: WorkoutHistoryView(viewModel: viewModel)) {
                            Text("すべて表示")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    }
                }
                
                if viewModel.workoutSessions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 40))
                            .foregroundColor(Color("AsaMutedSage").opacity(0.5))
                        Text("まだ運動記録がありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("最初の運動を記録してみましょう！")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(viewModel.workoutSessions.prefix(3))) { session in
                            WorkoutRowView(session: session)
                        }
                    }
                }
            }
        }
    }
}

struct WorkoutRowView: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack {
            Text(session.workoutType.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.workoutType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(session.dateFormatted) • \(session.timeFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.durationFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                Text(session.intensity.displayName)
                    .font(.caption)
                    .foregroundColor(Color(session.intensity.color))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
