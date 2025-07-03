//
//  WorkoutGoalsView.swift
//  AsaWorkoutLog
//
//  Created on 2025/07/03
//

import SwiftUI

struct WorkoutGoalsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var tempGoalMinutes: Double = 150
    @State private var showingGoalEditor = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 現在の目標
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("週間目標")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                
                                Spacer()
                                
                                Button("編集") {
                                    tempGoalMinutes = viewModel.weeklyGoal / 60
                                    showingGoalEditor = true
                                }
                                .font(.subheadline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                            
                            HStack {
                                Text("目標時間")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(viewModel.weeklyGoal / 60))分")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("今週の進捗")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(viewModel.thisWeekDuration / 60))分")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(viewModel.weeklyProgress >= 1.0 ? .green : Color("AsaCoffeeBrown"))
                            }
                            
                            ProgressView(value: viewModel.weeklyProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .scaleEffect(x: 1, y: 3, anchor: .center)
                            
                            HStack {
                                Text("達成率")
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
                    
                    // 推奨目標
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("推奨目標")
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            Text("WHO（世界保健機関）は、成人に対して週に150分以上の中強度有酸素運動を推奨しています。")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                            
                            VStack(spacing: 12) {
                                GoalRecommendationRow(
                                    title: "初心者",
                                    minutes: 75,
                                    description: "週に75分から始めましょう"
                                ) {
                                    viewModel.updateWeeklyGoal(75 * 60)
                                }
                                
                                GoalRecommendationRow(
                                    title: "推奨レベル",
                                    minutes: 150,
                                    description: "WHO推奨の週150分"
                                ) {
                                    viewModel.updateWeeklyGoal(150 * 60)
                                }
                                
                                GoalRecommendationRow(
                                    title: "アクティブ",
                                    minutes: 300,
                                    description: "より多くの健康効果を得るため"
                                ) {
                                    viewModel.updateWeeklyGoal(300 * 60)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // 今週の詳細
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("今週の詳細")
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            if viewModel.thisWeekWorkouts.isEmpty {
                                Text("今週はまだワークアウトがありません")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(viewModel.thisWeekWorkouts.sorted(by: { $0.date > $1.date })) { workout in
                                    WeeklyWorkoutRow(workout: workout)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // 目標達成のヒント
                    AsaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("目標達成のヒント")
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TipRow(icon: "calendar", text: "毎日少しずつ運動する習慣を作る")
                                TipRow(icon: "clock", text: "短時間でも継続することが大切")
                                TipRow(icon: "heart", text: "楽しめる運動を選ぶ")
                                TipRow(icon: "person.2", text: "友人や家族と一緒に運動する")
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("目標")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingGoalEditor) {
            GoalEditorView(
                goalMinutes: $tempGoalMinutes,
                onSave: {
                    viewModel.updateWeeklyGoal(tempGoalMinutes * 60)
                    showingGoalEditor = false
                },
                onCancel: {
                    showingGoalEditor = false
                }
            )
        }
    }
}

struct GoalRecommendationRow: View {
    let title: String
    let minutes: Int
    let description: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(minutes)分")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Button("設定") {
                action()
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("AsaCoffeeBrown"))
            .foregroundColor(.white)
            .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct WeeklyWorkoutRow: View {
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
        formatter.dateFormat = "M/d (E) HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .frame(width: 16)
            
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct GoalEditorView: View {
    @Binding var goalMinutes: Double
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("週間目標を設定")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("1週間の運動目標時間を設定してください")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    Text("\(Int(goalMinutes))分")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Slider(value: $goalMinutes, in: 30...600, step: 15)
                        .accentColor(Color("AsaCoffeeBrown"))
                    
                    HStack {
                        Text("30分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("600分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("目標設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave()
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutGoalsView(viewModel: WorkoutViewModel())
}