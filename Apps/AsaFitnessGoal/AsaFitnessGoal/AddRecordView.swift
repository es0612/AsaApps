//
//  AddRecordView.swift
//  AsaFitnessGoal
//
//  Created on 2025/07/19
//

import SwiftUI

struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: FitnessViewModel
    
    @State private var selectedGoal: FitnessGoal?
    @State private var value = ""
    @State private var note = ""
    @State private var recordDate = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("運動記録を追加")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("目標を選択")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaMocha"))
                                
                                if viewModel.activeGoals.isEmpty {
                                    Text("記録可能な目標がありません。まず目標を作成してください。")
                                        .font(.body)
                                        .foregroundColor(Color("AsaMutedSage"))
                                        .padding()
                                        .background(Color("AsaSoftCream"))
                                        .cornerRadius(8)
                                } else {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 8) {
                                        ForEach(viewModel.activeGoals, id: \.id) { goal in
                                            GoalSelectionRow(
                                                goal: goal,
                                                isSelected: selectedGoal?.id == goal.id,
                                                action: { selectedGoal = goal }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if selectedGoal != nil {
                        AsaCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("記録内容")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("実績値")
                                        .font(.headline)
                                        .foregroundColor(Color("AsaMocha"))
                                    
                                    HStack {
                                        TextField("実績値を入力", text: $value)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                        
                                        if let goal = selectedGoal {
                                            Text(goal.category.unit)
                                                .font(.body)
                                                .foregroundColor(Color("AsaMutedSage"))
                                                .frame(minWidth: 30)
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("メモ（オプション）")
                                        .font(.headline)
                                        .foregroundColor(Color("AsaMocha"))
                                    
                                    TextField("メモを入力", text: $note, axis: .vertical)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .lineLimit(2...4)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("記録日時")
                                        .font(.headline)
                                        .foregroundColor(Color("AsaMocha"))
                                    
                                    DatePicker(
                                        "記録日時",
                                        selection: $recordDate,
                                        in: ...Date(),
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .datePickerStyle(CompactDatePickerStyle())
                                }
                            }
                        }
                        
                        VStack(spacing: 12) {
                            AsaButton(
                                title: "記録を保存",
                                action: saveRecord,
                                color: Color("AsaCoffeeBrown"),
                                isEnabled: canSaveRecord
                            )
                            
                            AsaButton(
                                title: "キャンセル",
                                action: { dismiss() },
                                color: Color("AsaMutedSage")
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("記録追加")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var canSaveRecord: Bool {
        selectedGoal != nil && !value.isEmpty && Double(value) != nil && Double(value)! > 0
    }
    
    private func saveRecord() {
        guard let goal = selectedGoal,
              let recordValue = Double(value),
              recordValue > 0 else { return }
        
        viewModel.addWorkoutRecord(
            goalId: goal.id,
            category: goal.category,
            value: recordValue,
            note: note
        )
        
        dismiss()
    }
}

// MARK: - 目標選択行
struct GoalSelectionRow: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: goal.category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color("AsaCoffeeBrown"))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : Color("AsaDarkSlate"))
                    
                    Text("\(goal.category.displayName) • \(goal.period.displayName)")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color("AsaMutedSage"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("目標: \(formatValue(goal.targetValue, for: goal.category))")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color("AsaMocha"))
                    
                    Text(goal.category.unit)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.6) : Color("AsaMutedSage"))
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color("AsaCoffeeBrown") : Color("AsaSoftCream"))
            .cornerRadius(10)
            .shadow(radius: isSelected ? 2 : 1)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func formatValue(_ value: Double, for category: GoalCategory) -> String {
        switch category {
        case .steps, .workouts:
            return String(format: "%.0f", value)
        case .distance:
            return String(format: "%.1f", value)
        case .activeTime, .calories:
            return String(format: "%.0f", value)
        }
    }
}

#Preview {
    AddRecordView(viewModel: FitnessViewModel())
}