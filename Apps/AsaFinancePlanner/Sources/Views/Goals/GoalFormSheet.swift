import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct GoalFormSheet: View {
    @State var viewModel: GoalViewModel
    let isEditing: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("目標名", text: $viewModel.goalName)

                    Picker("カテゴリ", selection: $viewModel.goalCategory) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.iconName)
                                .tag(category)
                        }
                    }

                    CurrencyTextField(title: "目標金額", value: $viewModel.goalTargetAmount)
                    CurrencyTextField(title: "現在の貯蓄額", value: $viewModel.goalCurrentAmount)
                }

                Section("期日") {
                    DatePicker(
                        "目標達成日",
                        selection: $viewModel.goalTargetDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                }

                Section("優先度") {
                    Picker("優先度", selection: $viewModel.goalPriority) {
                        Text("低").tag(0)
                        Text("中").tag(1)
                        Text("高").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Section("メモ") {
                    TextEditor(text: $viewModel.goalNote)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(isEditing ? "目標を編集" : "新しい目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "更新" : "追加") {
                        if isEditing {
                            if let goal = viewModel.selectedGoal {
                                viewModel.updateGoal(goal)
                            }
                        } else {
                            viewModel.addGoal()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .disabled(viewModel.goalName.isEmpty || viewModel.goalTargetAmount <= .zero)
                }
            }
        }
    }
}
