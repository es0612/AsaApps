//
//  BudgetPlanView.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import AsaUIKit

struct BudgetPlanView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @State private var showingCreateBudget = false
    @State private var selectedBudget: Budget?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 現在の予算
                    if let currentBudget = viewModel.currentBudget {
                        currentBudgetCard(currentBudget)
                    }

                    // MARK: - すべての予算
                    VStack(alignment: .leading, spacing: 12) {
                        Text("予算一覧")
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)

                        ForEach(viewModel.budgets) { budget in
                            BudgetRowCard(budget: budget)
                                .onTapGesture {
                                    selectedBudget = budget
                                }
                        }
                    }

                    // MARK: - カテゴリ別予算設定
                    categoryBudgetSection
                }
                .padding()
            }
            .navigationTitle("予算計画")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateBudget = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showingCreateBudget) {
                CreateBudgetView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedBudget) { budget in
                BudgetDetailView(budget: budget)
                    .environmentObject(viewModel)
            }
        }
    }

    // MARK: - Current Budget Card
    private func currentBudgetCard(_ budget: Budget) -> some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("現在の予算")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                        Text(budget.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AsaColors.darkSlate)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(budget.periodLabel)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                        Text("\(budget.daysRemaining)日残り")
                            .font(.caption)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }

                // 予算使用状況
                VStack(spacing: 8) {
                    HStack {
                        Text("予算額")
                        Spacer()
                        Text(formatCurrency(budget.totalAmount))
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)

                    HStack {
                        Text("使用額")
                        Spacer()
                        Text(formatCurrency(budget.totalAmount - budget.remainingAmount))
                            .fontWeight(.medium)
                            .foregroundColor(AsaColors.mocha)
                    }
                    .font(.subheadline)

                    Divider()

                    HStack {
                        Text("残額")
                        Spacer()
                        Text(formatCurrency(budget.remainingAmount))
                            .fontWeight(.bold)
                            .foregroundColor(
                                budget.spentPercentage > 80 ? Color.red :
                                budget.spentPercentage > 60 ? Color.orange :
                                Color.green
                            )
                    }
                    .font(.subheadline)
                }

                // プログレスバー
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(AsaColors.softCream)
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: budget.statusColor) ?? AsaColors.coffeeBrown)
                            .frame(
                                width: min(
                                    geometry.size.width * (budget.spentPercentage / 100),
                                    geometry.size.width
                                ),
                                height: 10
                            )
                    }
                }
                .frame(height: 10)

                Text("\(Int(budget.spentPercentage))% 使用済み")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
    }

    // MARK: - Category Budget Section
    private var categoryBudgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ別予算")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            AsaCard {
                VStack(spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                                .frame(width: 24)
                            Text(category.name)
                                .font(.subheadline)
                                .foregroundColor(AsaColors.darkSlate)
                            Spacer()
                            Text(formatCurrency(category.budgetLimit))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AsaColors.mocha)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}

// MARK: - Budget Row Card
struct BudgetRowCard: View {
    let budget: Budget

    var body: some View {
        AsaCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AsaColors.darkSlate)
                    Text(budget.periodLabel)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(budget.totalAmount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AsaColors.coffeeBrown)
                    if budget.isActive {
                        Text("アクティブ")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(Color.green)
                            .cornerRadius(4)
                    }
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}

// MARK: - Create Budget View
struct CreateBudgetView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amount = ""
    @State private var period: BudgetPeriod = .monthly
    @State private var startDate = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("予算情報") {
                    TextField("予算名", text: $name)
                    HStack {
                        Text("¥")
                            .foregroundColor(AsaColors.mutedSage)
                        TextField("予算額", text: $amount)
                            .keyboardType(.numberPad)
                    }
                }

                Section("期間") {
                    Picker("期間タイプ", selection: $period) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker(
                        "開始日",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle("新しい予算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        createBudget()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func createBudget() {
        guard !name.isEmpty else {
            alertMessage = "予算名を入力してください"
            showingAlert = true
            return
        }

        guard let amountValue = Double(amount), amountValue > 0 else {
            alertMessage = "正しい予算額を入力してください"
            showingAlert = true
            return
        }

        viewModel.createBudget(name: name, amount: amountValue, period: period)
        dismiss()
    }
}

// MARK: - Budget Detail View
struct BudgetDetailView: View {
    let budget: Budget
    @EnvironmentObject private var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("予算情報") {
                    LabeledContent("名前", value: budget.name)
                    LabeledContent("予算額", value: formatCurrency(budget.totalAmount))
                    LabeledContent("期間", value: budget.period.rawValue)
                    LabeledContent("開始日") {
                        Text(budget.startDate, format: .dateTime.year().month().day())
                    }
                    LabeledContent("終了日") {
                        Text(budget.endDate, format: .dateTime.year().month().day())
                    }
                }

                Section("使用状況") {
                    LabeledContent("使用額", value: formatCurrency(budget.totalAmount - budget.remainingAmount))
                    LabeledContent("残額", value: formatCurrency(budget.remainingAmount))
                    LabeledContent("使用率", value: "\(Int(budget.spentPercentage))%")
                    LabeledContent("残り日数", value: "\(budget.daysRemaining)日")
                }

                if budget.isActive {
                    Section {
                        Button("この予算を無効化") {
                            budget.isActive = false
                            dismiss()
                        }
                        .foregroundColor(Color.orange)
                    }
                } else {
                    Section {
                        Button("この予算を有効化") {
                            budget.isActive = true
                            viewModel.switchBudget(to: budget)
                            dismiss()
                        }
                        .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .navigationTitle("予算詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}