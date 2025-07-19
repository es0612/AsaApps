//
//  EditGoalView.swift
//  AsaFitnessGoal
//
//  Created on 2025/07/19
//

import SwiftUI

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let goal: FitnessGoal
    let viewModel: FitnessViewModel
    
    @State private var title = ""
    @State private var targetValue = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("目標を編集")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("目標名")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaMocha"))
                                
                                TextField("目標名を入力", text: $title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("カテゴリ")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaMocha"))
                                
                                HStack {
                                    Image(systemName: goal.category.icon)
                                        .font(.title2)
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                    
                                    Text(goal.category.displayName)
                                        .font(.body)
                                        .foregroundColor(Color("AsaDarkSlate"))
                                    
                                    Spacer()
                                    
                                    Text("（変更不可）")
                                        .font(.caption)
                                        .foregroundColor(Color("AsaMutedSage"))
                                }
                                .padding()
                                .background(Color("AsaSoftCream"))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("目標値と期間")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("目標値")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaMocha"))
                                
                                HStack {
                                    TextField("目標値を入力", text: $targetValue)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                    
                                    Text(goal.category.unit)
                                        .font(.body)
                                        .foregroundColor(Color("AsaMutedSage"))
                                        .frame(minWidth: 30)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("期間")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaMocha"))
                                
                                HStack {
                                    Text(goal.period.displayName)
                                        .font(.body)
                                        .foregroundColor(Color("AsaDarkSlate"))
                                    
                                    Spacer()
                                    
                                    Text("（変更不可）")
                                        .font(.caption)
                                        .foregroundColor(Color("AsaMutedSage"))
                                }
                                .padding()
                                .background(Color("AsaSoftCream"))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    VStack(spacing: 12) {
                        AsaButton(
                            title: "変更を保存",
                            action: updateGoal,
                            color: Color("AsaCoffeeBrown"),
                            isEnabled: canUpdateGoal
                        )
                        
                        AsaButton(
                            title: "キャンセル",
                            action: { dismiss() },
                            color: Color("AsaMutedSage")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("目標編集")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                initializeFields()
            }
        }
    }
    
    private var canUpdateGoal: Bool {
        !title.isEmpty && !targetValue.isEmpty && Double(targetValue) != nil && Double(targetValue)! > 0
    }
    
    private func initializeFields() {
        title = goal.title
        targetValue = String(goal.targetValue)
    }
    
    private func updateGoal() {
        guard let value = Double(targetValue), value > 0 else { return }
        
        viewModel.updateGoal(goal, title: title, targetValue: value)
        viewModel.hideEditGoalSheet()
        dismiss()
    }
}

#Preview {
    let sampleGoal = FitnessGoal(
        title: "毎日10,000歩",
        category: .steps,
        targetValue: 10000,
        period: .daily
    )
    
    return EditGoalView(goal: sampleGoal, viewModel: FitnessViewModel())
}