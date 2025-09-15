//
//  AddTransactionView.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import AsaUIKit

struct AddTransactionView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - State Properties
    @State private var title = ""
    @State private var amount = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var selectedMember: FamilyMember?
    @State private var date = Date()
    @State private var note = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 基本情報
                Section("基本情報") {
                    TextField("タイトル", text: $title)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Text("¥")
                            .foregroundColor(AsaColors.mutedSage)
                        TextField("金額", text: $amount)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }

                    Picker("種類", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: - カテゴリ選択
                Section("カテゴリ") {
                    Picker("カテゴリを選択", selection: $selectedCategory) {
                        Text("未選択").tag(nil as Category?)
                        ForEach(viewModel.categories, id: \.id) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: - メンバー選択
                Section("記録者") {
                    Picker("メンバーを選択", selection: $selectedMember) {
                        Text("未選択").tag(nil as FamilyMember?)
                        ForEach(viewModel.familyMembers, id: \.id) { member in
                            Text(member.name).tag(member as FamilyMember?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: - 日付選択
                Section("日付") {
                    DatePicker(
                        "日付",
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                }

                // MARK: - メモ
                Section("メモ") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("取引を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTransaction()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || amount.isEmpty)
                }
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Helper Methods
    private func saveTransaction() {
        // 入力検証
        guard !title.isEmpty else {
            alertMessage = "タイトルを入力してください"
            showingAlert = true
            return
        }

        guard let amountValue = Double(amount), amountValue > 0 else {
            alertMessage = "正しい金額を入力してください"
            showingAlert = true
            return
        }

        // 取引を作成
        let transaction = Transaction(
            amount: amountValue,
            type: type,
            title: title,
            note: note.isEmpty ? nil : note,
            date: date,
            category: selectedCategory,
            member: selectedMember
        )

        // ViewModelに追加
        viewModel.addTransaction(transaction)

        // 画面を閉じる
        dismiss()
    }
}