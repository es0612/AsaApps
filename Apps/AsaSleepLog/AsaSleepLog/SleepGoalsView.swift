//
//  SleepGoalsView.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct SleepGoalsView: View {
    @ObservedObject var viewModel: SleepLogViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tempGoal: SleepGoal
    
    init(viewModel: SleepLogViewModel) {
        self.viewModel = viewModel
        self._tempGoal = State(initialValue: viewModel.sleepGoal)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 目標睡眠時間
                    GoalSection(title: "目標睡眠時間", icon: "clock.fill") {
                        VStack(spacing: 15) {
                            SleepTimeSelector(
                                title: "就寝時間",
                                time: $tempGoal.targetBedTime,
                                icon: "moon.fill"
                            )
                            
                            SleepTimeSelector(
                                title: "起床時間",
                                time: $tempGoal.targetWakeTime,
                                icon: "sun.max.fill"
                            )
                            
                            HStack {
                                Text("目標睡眠時間:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(tempGoal.targetSleepDurationFormatted)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                        }
                    }
                    
                    // 睡眠効率目標
                    GoalSection(title: "睡眠効率目標", icon: "speedometer") {
                        VStack(spacing: 10) {
                            HStack {
                                Text("最低睡眠効率:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(tempGoal.minimumSleepEfficiency))%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                            
                            Slider(
                                value: $tempGoal.minimumSleepEfficiency,
                                in: 70...95,
                                step: 5
                            )
                            .accentColor(Color("AsaCoffeeBrown"))
                            
                            HStack {
                                Text("70%")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("95%")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // 現在の達成状況
                    GoalSection(title: "現在の達成状況", icon: "target") {
                        VStack(spacing: 15) {
                            GoalAchievementRow(
                                title: "今週の達成率",
                                value: "\(Int(viewModel.goalAchievementRate(for: .week)))%",
                                isAchieved: viewModel.goalAchievementRate(for: .week) >= 70
                            )
                            
                            GoalAchievementRow(
                                title: "今月の達成率",
                                value: "\(Int(viewModel.goalAchievementRate(for: .month)))%",
                                isAchieved: viewModel.goalAchievementRate(for: .month) >= 70
                            )
                            
                            GoalAchievementRow(
                                title: "平均睡眠効率",
                                value: String(format: "%.1f%%", viewModel.averageSleepEfficiency),
                                isAchieved: viewModel.averageSleepEfficiency >= tempGoal.minimumSleepEfficiency
                            )
                        }
                    }
                    
                    // 保存ボタン
                    AsaButton(title: "目標を保存") {
                        viewModel.updateSleepGoal(tempGoal)
                        dismiss()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("睡眠目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .background(Color("AsaSoftCream").opacity(0.3))
        }
    }
}

struct GoalSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        AsaCard {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title2)
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                }
                
                content
            }
        }
        .padding(.horizontal)
    }
}

struct SleepTimeSelector: View {
    let title: String
    @Binding var time: Date
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("AsaMutedSage"))
                .font(.caption)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            DatePicker("", selection: $time, displayedComponents: [.hourAndMinute])
                .labelsHidden()
                .scaleEffect(0.9)
        }
    }
}

struct GoalAchievementRow: View {
    let title: String
    let value: String
    let isAchieved: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isAchieved ? Color("AsaCoffeeBrown") : Color("AsaMutedSage"))
                
                Image(systemName: isAchieved ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isAchieved ? .green : .red)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    SleepGoalsView(viewModel: SleepLogViewModel())
}