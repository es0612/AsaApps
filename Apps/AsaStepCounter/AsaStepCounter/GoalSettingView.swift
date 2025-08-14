//
//  GoalSettingView.swift
//  AsaStepCounter
//
//  Created on 2025/08/15
//

import SwiftUI
import SwiftData

struct GoalSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let stepRecord: StepRecord
    
    @State private var newGoal: Int
    @State private var customGoalText: String = ""
    @State private var showingCustomInput = false
    
    // プリセット目標値
    private let presetGoals = [5000, 8000, 10000, 12000, 15000, 20000]
    
    init(stepRecord: StepRecord) {
        self.stepRecord = stepRecord
        self._newGoal = State(initialValue: stepRecord.dailyGoal)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [Color("AsaSoftCream"), Color("AsaDarkSlate").opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 現在の目標表示
                        currentGoalCard
                        
                        // プリセット目標選択
                        presetGoalsSection
                        
                        // カスタム目標入力
                        customGoalSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("目標設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveGoal()
                    }
                    .fontWeight(.semibold)
                    .disabled(newGoal == stepRecord.dailyGoal)
                }
            }
        }
    }
    
    // MARK: - 現在の目標カード
    private var currentGoalCard: some View {
        AsaCard {
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .font(.system(size: 40))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("現在の目標")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(newGoal)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .contentTransition(.numericText())
                        .animation(.bouncy(duration: 0.3), value: newGoal)
                    
                    Text("歩")
                        .font(.title2)
                        .foregroundColor(Color("AsaMutedSage"))
                        .padding(.bottom, 4)
                }
                
                if newGoal != stepRecord.dailyGoal {
                    Text("変更後: \(stepRecord.dailyGoal) → \(newGoal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color("AsaSoftCream").opacity(0.5))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - プリセット目標セクション
    private var presetGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("おすすめ目標")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .padding(.leading, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(presetGoals, id: \.self) { goal in
                    Button(action: {
                        withAnimation(.bouncy(duration: 0.3)) {
                            newGoal = goal
                            showingCustomInput = false
                        }
                    }) {
                        AsaCard {
                            VStack(spacing: 8) {
                                Text("\(goal)")
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(newGoal == goal ? .white : Color("AsaCoffeeBrown"))
                                
                                Text("歩")
                                    .font(.caption)
                                    .foregroundColor(newGoal == goal ? .white.opacity(0.8) : .secondary)
                                
                                if goal == stepRecord.dailyGoal {
                                    Text("現在")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(newGoal == goal ? .white.opacity(0.2) : Color("AsaSoftCream"))
                                        .cornerRadius(4)
                                        .foregroundColor(newGoal == goal ? .white : .secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background(newGoal == goal ? Color("AsaCoffeeBrown") : Color.clear)
                            .cornerRadius(15)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - カスタム目標セクション
    private var customGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カスタム目標")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .padding(.leading, 4)
            
            AsaCard {
                VStack(spacing: 16) {
                    if showingCustomInput {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("目標歩数を入力してください（1,000〜50,000歩）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("例: 12000", text: $customGoalText)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                    .onChange(of: customGoalText) { _, newValue in
                                        // 数字のみ許可し、範囲をチェック
                                        let filtered = newValue.filter { $0.isNumber }
                                        customGoalText = filtered
                                        
                                        if let goal = Int(filtered), goal >= 1000 && goal <= 50000 {
                                            newGoal = goal
                                        }
                                    }
                                
                                Text("歩")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 12) {
                                Button("適用") {
                                    if let goal = Int(customGoalText), goal >= 1000 && goal <= 50000 {
                                        withAnimation(.bouncy(duration: 0.3)) {
                                            newGoal = goal
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color("AsaCoffeeBrown"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .disabled(customGoalText.isEmpty || Int(customGoalText) == nil || Int(customGoalText)! < 1000 || Int(customGoalText)! > 50000)
                                
                                Button("キャンセル") {
                                    withAnimation {
                                        showingCustomInput = false
                                        customGoalText = ""
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color("AsaMutedSage"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        AsaButton(
                            title: "カスタム目標を設定",
                            action: {
                                withAnimation {
                                    showingCustomInput = true
                                    customGoalText = "\(newGoal)"
                                }
                            },
                            color: Color("AsaMutedSage")
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 目標保存
    private func saveGoal() {
        withAnimation {
            stepRecord.updateDailyGoal(newGoal)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("目標保存エラー: \(error)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StepRecord.self, configurations: config)
    let record = StepRecord(date: Date(), dailyGoal: 10000)
    
    GoalSettingView(stepRecord: record)
        .modelContainer(container)
}