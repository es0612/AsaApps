//
//  AddGoalView.swift
//  AsaFitnessGoal
//
//  Created on 2025/07/19
//

import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: FitnessViewModel
    
    @State private var title = ""
    @State private var selectedCategory: GoalCategory = .steps
    @State private var targetValue = ""
    @State private var selectedPeriod: GoalPeriod = .daily
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("新しい目標を設定")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("目標名")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaMocha"))
                                
                                TextField("例: 毎日10,000歩", text: $title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("カテゴリ")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaMocha"))
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(GoalCategory.allCases, id: \.self) { category in
                                        CategorySelectionCard(
                                            category: category,
                                            isSelected: selectedCategory == category,
                                            action: { selectedCategory = category }
                                        )
                                    }
                                }
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
                                    
                                    Text(selectedCategory.unit)
                                        .font(.body)
                                        .foregroundColor(Color("AsaMutedSage"))
                                        .frame(minWidth: 30)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("期間")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaMocha"))
                                
                                HStack(spacing: 12) {
                                    ForEach(GoalPeriod.allCases, id: \.self) { period in
                                        PeriodSelectionButton(
                                            period: period,
                                            isSelected: selectedPeriod == period,
                                            action: { selectedPeriod = period }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(spacing: 12) {
                        AsaButton(
                            title: "目標を作成",
                            action: createGoal,
                            color: Color("AsaCoffeeBrown"),
                            isEnabled: canCreateGoal
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
            .navigationTitle("目標作成")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var canCreateGoal: Bool {
        !title.isEmpty && !targetValue.isEmpty && Double(targetValue) != nil && Double(targetValue)! > 0
    }
    
    private func createGoal() {
        guard let value = Double(targetValue), value > 0 else { return }
        
        viewModel.addGoal(
            title: title,
            category: selectedCategory,
            targetValue: value,
            period: selectedPeriod
        )
        
        dismiss()
    }
}

// MARK: - カテゴリ選択カード
struct CategorySelectionCard: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color("AsaCoffeeBrown"))
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : Color("AsaDarkSlate"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color("AsaCoffeeBrown") : Color("AsaSoftCream"))
            .cornerRadius(10)
            .shadow(radius: isSelected ? 3 : 1)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 期間選択ボタン
struct PeriodSelectionButton: View {
    let period: GoalPeriod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(period.displayName)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : Color("AsaCoffeeBrown"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color("AsaCoffeeBrown") : Color("AsaSoftCream"))
                .cornerRadius(8)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    AddGoalView(viewModel: FitnessViewModel())
}