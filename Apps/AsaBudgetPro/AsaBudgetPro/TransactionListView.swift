//
//  TransactionListView.swift
//  AsaBudgetPro
//  
//  Created on 2025/08/03
//

import SwiftUI

struct TransactionListView: View {
    @State var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTransaction = false
    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText = ""
    
    enum TransactionFilter: String, CaseIterable {
        case all = "すべて"
        case income = "収入"
        case expense = "支出"
    }
    
    var filteredTransactions: [Transaction] {
        var transactions = viewModel.transactions
        
        // タイプフィルター
        switch selectedFilter {
        case .income:
            transactions = transactions.filter { $0.transactionType == .income }
        case .expense:
            transactions = transactions.filter { $0.transactionType == .expense }
        case .all:
            break
        }
        
        // 検索テキストフィルター
        if !searchText.isEmpty {
            transactions = transactions.filter {
                $0.categoryName.localizedCaseInsensitiveContains(searchText) ||
                $0.memo.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return transactions
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color("AsaSoftCream"), Color("AsaMocha")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    filterView
                    
                    searchView
                    
                    transactionListView
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(viewModel: viewModel)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("閉じる") {
                dismiss()
            }
            .font(.body.weight(.medium))
            .foregroundColor(Color("AsaMutedSage"))
            
            Spacer()
            
            Text("取引履歴")
                .font(.title2.weight(.bold))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Spacer()
            
            Button {
                showingAddTransaction = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
    }
    
    private var filterView: some View {
        AsaCard {
            VStack(spacing: 12) {
                HStack {
                    Text("フィルター")
                        .font(.headline.weight(.medium))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    Text("\(filteredTransactions.count)件")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                }
                
                Picker("フィルター", selection: $selectedFilter) {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.horizontal)
    }
    
    private var searchView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("AsaMutedSage"))
            
            TextField("カテゴリやメモで検索...", text: $searchText)
                .font(.body)
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var transactionListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredTransactions, id: \.id) { transaction in
                        TransactionRow(
                            transaction: transaction,
                            onDelete: {
                                viewModel.deleteTransaction(transaction)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("取引履歴がありません")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text("「+」ボタンから取引を追加してください")
                .font(.body)
                .foregroundColor(Color("AsaMutedSage"))
                .multilineTextAlignment(.center)
            
            AsaButton(
                title: "取引を追加",
                action: { showingAddTransaction = true },
                color: Color("AsaCoffeeBrown")
            )
            .frame(maxWidth: 200)
        }
        .padding()
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        AsaCard {
            HStack(spacing: 12) {
                // アイコンと色
                Circle()
                    .fill(transaction.transactionType == .income ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Image(systemName: transaction.transactionType.icon)
                    .font(.title3)
                    .foregroundColor(transaction.transactionType == .income ? .green : .red)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.categoryName)
                        .font(.body.weight(.medium))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    if !transaction.memo.isEmpty {
                        Text(transaction.memo)
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                            .lineLimit(2)
                    }
                    
                    Text(transaction.date, format: .dateTime.year().month().day().weekday(.wide))
                        .font(.caption2)
                        .foregroundColor(Color("AsaMutedSage"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("¥\(Int(transaction.amount))")
                        .font(.headline.weight(.bold))
                        .foregroundColor(transaction.transactionType == .income ? .green : .red)
                    
                    Text(transaction.transactionType.rawValue)
                        .font(.caption2)
                        .foregroundColor(Color("AsaMutedSage"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color("AsaSoftCream"))
                        .cornerRadius(4)
                }
                
                Button {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .alert("取引を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("この取引を削除してもよろしいですか？")
        }
    }
}

#Preview {
    TransactionListView(viewModel: BudgetViewModel())
}
