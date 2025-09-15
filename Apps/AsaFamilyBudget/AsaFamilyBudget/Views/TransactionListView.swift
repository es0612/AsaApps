//
//  TransactionListView.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import AsaUIKit

struct TransactionListView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @State private var searchText = ""
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?
    @State private var showingDeleteAlert = false
    @State private var transactionToDelete: Transaction?

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedTransactions, id: \.key) { date, transactions in
                    Section(header: sectionHeader(for: date)) {
                        ForEach(transactions) { transaction in
                            TransactionRowView(transaction: transaction)
                                .onTapGesture {
                                    selectedTransaction = transaction
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        transactionToDelete = transaction
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "取引を検索")
            .navigationTitle("取引履歴")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(transaction: transaction)
                    .environmentObject(viewModel)
            }
            .alert("取引を削除", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    if let transaction = transactionToDelete {
                        viewModel.deleteTransaction(transaction)
                    }
                }
            } message: {
                Text("この取引を削除してもよろしいですか？")
            }
        }
    }

    // MARK: - Computed Properties
    private var filteredTransactions: [Transaction] {
        if searchText.isEmpty {
            return viewModel.transactions
        }
        return viewModel.transactions.filter { transaction in
            transaction.title.localizedCaseInsensitiveContains(searchText) ||
            transaction.note?.localizedCaseInsensitiveContains(searchText) == true ||
            transaction.category?.name.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    private var groupedTransactions: [(key: Date, value: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions.sorted { $0.date > $1.date }) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    // MARK: - Helper Views
    private func sectionHeader(for date: Date) -> some View {
        HStack {
            Text(formatDate(date))
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)
            Spacer()
            Text(formatDayTotal(for: date))
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
        }
    }

    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "MM月dd日 (E)"
        return formatter.string(from: date)
    }

    private func formatDayTotal(for date: Date) -> String {
        let dayTransactions = filteredTransactions.filter { transaction in
            Calendar.current.isDate(transaction.date, inSameDayAs: date)
        }
        let total = dayTransactions.reduce(0) { result, transaction in
            transaction.type == .income ? result + transaction.amount : result - transaction.amount
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: abs(total))) ?? "¥0"
        return total >= 0 ? "+\(formatted)" : "-\(formatted)"
    }
}

// MARK: - Transaction Row View
struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            // カテゴリアイコン
            if let category = transaction.category {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .frame(width: 32, height: 32)
                    .background(category.color.opacity(0.1))
                    .clipShape(Circle())
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(AsaColors.mutedSage)
                    .frame(width: 32, height: 32)
            }

            // 取引情報
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.subheadline)
                    .foregroundColor(AsaColors.darkSlate)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let category = transaction.category {
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    if let member = transaction.member {
                        Text("• \(member.name)")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
            }

            Spacer()

            // 金額
            Text(transaction.formattedAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(
                    transaction.type == .income ?
                    Color.green : AsaColors.mocha
                )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Transaction Detail View
struct TransactionDetailView: View {
    let transaction: Transaction
    @EnvironmentObject private var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("取引情報") {
                    LabeledContent("タイトル", value: transaction.title)
                    LabeledContent("金額", value: transaction.formattedAmount)
                    LabeledContent("種類", value: transaction.type.rawValue)
                    LabeledContent("日付") {
                        Text(transaction.date, format: .dateTime.year().month().day())
                    }
                }

                if let category = transaction.category {
                    Section("カテゴリ") {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.name)
                        }
                    }
                }

                if let member = transaction.member {
                    Section("記録者") {
                        HStack {
                            Image(systemName: member.avatarName)
                                .foregroundColor(Color(hex: member.colorHex) ?? AsaColors.coffeeBrown)
                            Text(member.name)
                        }
                    }
                }

                if let note = transaction.note, !note.isEmpty {
                    Section("メモ") {
                        Text(note)
                    }
                }
            }
            .navigationTitle("取引詳細")
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
}