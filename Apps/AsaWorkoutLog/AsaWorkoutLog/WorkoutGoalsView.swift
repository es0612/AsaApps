//
//  WorkoutGoalsView.swift
//  AsaWorkoutLog
//  
//  Created on 2025/07/01
//

import SwiftUI

struct WorkoutGoalsView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var editingGoal: WorkoutGoal
    @State private var isEditing = false
    
    init(viewModel: WorkoutViewModel) {
        self.viewModel = viewModel
        self._editingGoal = State(initialValue: viewModel.workoutGoal)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 現在の目標達成状況
                CurrentGoalProgressView(viewModel: viewModel)
                
                // 目標設定カード
                GoalSettingsView(
                    editingGoal: $editingGoal,
                    isEditing: $isEditing,
                    viewModel: viewModel
                )
                
                // 目標達成のためのアドバイス
                GoalAdviceView(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("運動目標")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(isEditing ? "保存" : "編集") {
            if isEditing {
                viewModel.updateWorkoutGoal(editingGoal)
            } else {
                editingGoal = viewModel.workoutGoal
            }
            isEditing.toggle()
        })
    }
}

struct CurrentGoalProgressView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var body: some View {
        AsaCard(backgroundColor: Color("AsaSoftCream").opacity(0.3)) {
            VStack(alignment: .leading, spacing: 16) {
                Text("今週の目標達成状況")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                VStack(spacing: 16) {
                    // 運動時間の進捗
                    GoalProgressRow(
                        title: "運動時間",
                        current: viewModel.thisWeekTotalMinutes,
                        target: viewModel.workoutGoal.weeklyTargetMinutes,
                        unit: "分",
                        progress: viewModel.thisWeekProgress,
                        color: Color("AsaCoffeeBrown")
                    )
                    
                    // セッション数の進捗
                    GoalProgressRow(
                        title: "運動回数",
                        current: viewModel.thisWeekSessionCount,
                        target: viewModel.workoutGoal.weeklyTargetSessions,
                        unit: "回",
                        progress: viewModel.thisWeekSessionProgress,
                        color: Color("AsaMutedSage")
                    )
                }
            }
        }
    }
}

struct GoalProgressRow: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(current)\(unit) / \(target)\(unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text(progress >= 1.0 ? "🎉 目標達成！" : "あと\(target - current)\(unit)")
                    .font(.caption)
                    .foregroundColor(progress >= 1.0 ? Color("AsaCoffeeBrown") : .secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
    }
}

struct GoalSettingsView: View {
    @Binding var editingGoal: WorkoutGoal
    @Binding var isEditing: Bool
    let viewModel: WorkoutViewModel
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("目標設定")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                if isEditing {
                    VStack(spacing: 16) {
                        // 週間運動時間目標
                        VStack(alignment: .leading, spacing: 8) {
                            Text("週間運動時間目標: \(editingGoal.weeklyTargetMinutes)分")
                                .font(.subheadline)
                            Slider(
                                value: Binding(
                                    get: { Double(editingGoal.weeklyTargetMinutes) },
                                    set: { editingGoal.weeklyTargetMinutes = Int($0) }
                                ),
                                in: 30...600,
                                step: 30
                            )
                            .accentColor(Color("AsaCoffeeBrown"))
                        }
                        
                        // 週間セッション数目標
                        VStack(alignment: .leading, spacing: 8) {
                            Text("週間運動回数目標: \(editingGoal.weeklyTargetSessions)回")
                                .font(.subheadline)
                            Slider(
                                value: Binding(
                                    get: { Double(editingGoal.weeklyTargetSessions) },
                                    set: { editingGoal.weeklyTargetSessions = Int($0) }
                                ),
                                in: 1...14,
                                step: 1
                            )
                            .accentColor(Color("AsaMutedSage"))
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Text("週間運動時間目標")
                                .font(.subheadline)
                            Spacer()
                            Text(viewModel.workoutGoal.weeklyTargetFormatted)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Image(systemName: "repeat")
                                .foregroundColor(Color("AsaMutedSage"))
                            Text("週間運動回数目標")
                                .font(.subheadline)
                            Spacer()
                            Text("\(viewModel.workoutGoal.weeklyTargetSessions)回")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
    }
}

struct GoalAdviceView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var advice: String {
        let currentProgress = viewModel.thisWeekProgress
        let sessionProgress = viewModel.thisWeekSessionProgress
        
        if currentProgress >= 1.0 && sessionProgress >= 1.0 {
            return "🎉 素晴らしい！今週の目標を達成しました。この調子で続けましょう！"
        } else if currentProgress >= 0.8 || sessionProgress >= 0.8 {
            return "💪 もう少しで目標達成です！頑張りましょう！"
        } else if currentProgress >= 0.5 || sessionProgress >= 0.5 {
            return "👍 良いペースで進んでいます。継続することが大切です。"
        } else {
            return "🌅 まだ始まったばかりです。小さな運動から始めて習慣化していきましょう。"
        }
    }
    
    var tips: [String] {
        var tips: [String] = []
        
        if viewModel.thisWeekTotalMinutes < viewModel.workoutGoal.weeklyTargetMinutes {
            let remaining = viewModel.workoutGoal.weeklyTargetMinutes - viewModel.thisWeekTotalMinutes
            tips.append("目標まであと\(remaining)分です。10-15分の運動を追加してみませんか？")
        }
        
        if viewModel.thisWeekSessionCount < viewModel.workoutGoal.weeklyTargetSessions {
            let remaining = viewModel.workoutGoal.weeklyTargetSessions - viewModel.thisWeekSessionCount
            tips.append("今週あと\(remaining)回運動すると目標達成です！")
        }
        
        if viewModel.workoutSessions.isEmpty {
            tips.append("ウォーキングやストレッチなど、軽い運動から始めてみましょう。")
        }
        
        if tips.isEmpty {
            tips.append("定期的な運動は健康維持に重要です。無理のない範囲で続けましょう。")
        }
        
        return tips
    }
    
    var body: some View {
        AsaCard(backgroundColor: Color("AsaMocha").opacity(0.1)) {
            VStack(alignment: .leading, spacing: 16) {
                Text("アドバイス")
                    .font(.headline)
                    .foregroundColor(Color("AsaMocha"))
                
                Text(advice)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb")
                                .foregroundColor(Color("AsaMocha"))
                                .font(.caption)
                            Text(tip)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        WorkoutGoalsView(viewModel: WorkoutViewModel())
    }
}