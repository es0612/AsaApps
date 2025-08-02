//
//  ContentView.swift
//  AsaBudgetPro
//  
//  Created on 2025/08/03
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BudgetViewModel()
    @State private var showingAddTransaction = false
    @State private var showingTransactionList = false
    @State private var showingBudgetSettings = false
    @State private var showingAnalytics = false
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    private var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // ヘッダー
                        headerView
                        
                        // 月次サマリー
                        monthlySummaryView
                        
                        // クイックアクション
                        quickActionsView
                        
                        // 最近の取引
                        recentTransactionsView
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.modelContext = modelContext
                viewModel.initializeDefaultCategories()
                viewModel.loadData()
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingTransactionList) {
                TransactionListView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingBudgetSettings) {
                BudgetSettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAnalytics) {
                AnalyticsView(viewModel: viewModel)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image("AsaPapaLabLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .shadow(radius: 1)
            
            Text("AsaBudgetPro")
                .font(.title.weight(.bold))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text("カテゴリ別収支管理")
                .font(.subheadline)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .padding(.top)
    }
    
    private var monthlySummaryView: some View {
        AsaCard {
            VStack(spacing: 16) {
                Text("\(currentMonth)月の収支サマリー")
                    .font(.headline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                HStack(spacing: 20) {
                    VStack {
                        Text("収入")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                        Text("¥\(Int(viewModel.getTotalIncomeForMonth(year: currentYear, month: currentMonth)))")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.green)
                    }
                    
                    VStack {
                        Text("支出")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                        Text("¥\(Int(viewModel.getTotalExpenseForMonth(year: currentYear, month: currentMonth)))")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.red)
                    }
                    
                    VStack {
                        Text("残高")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                        let balance = viewModel.getTotalIncomeForMonth(year: currentYear, month: currentMonth) - viewModel.getTotalExpenseForMonth(year: currentYear, month: currentMonth)
                        Text("¥\(Int(balance))")
                            .font(.title2.weight(.bold))
                            .foregroundColor(balance >= 0 ? .green : .red)
                    }
                }
            }
        }
    }
    
    private var quickActionsView: some View {
        VStack(spacing: 12) {
            Text("クイックアクション")
                .font(.headline.weight(.medium))
                .foregroundColor(Color("AsaCoffeeBrown"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    AsaButton(
                        title: "取引追加",
                        action: { showingAddTransaction = true },
                        color: Color("AsaCoffeeBrown")
                    )
                    
                    AsaButton(
                        title: "履歴表示",
                        action: { showingTransactionList = true },
                        color: Color("AsaMutedSage")
                    )
                }
                
                HStack(spacing: 12) {
                    AsaButton(
                        title: "予算設定",
                        action: { showingBudgetSettings = true },
                        color: Color("AsaMocha")
                    )
                    
                    AsaButton(
                        title: "分析表示",
                        action: { showingAnalytics = true },
                        color: Color("AsaDarkSlate")
                    )
                }
            }
        }
    }
    
    private var recentTransactionsView: some View {
        AsaCard {
            VStack(spacing: 12) {
                HStack {
                    Text("最近の取引")
                        .font(.headline.weight(.medium))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    Button("すべて表示") {
                        showingTransactionList = true
                    }
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
                }
                
                if viewModel.getRecentTransactions().isEmpty {
                    Text("取引履歴がありません")
                        .font(.body)
                        .foregroundColor(Color("AsaMutedSage"))
                        .padding()
                } else {
                    ForEach(viewModel.getRecentTransactions(), id: \.id) { transaction in
                        HStack {
                            Image(systemName: transaction.transactionType.icon)
                                .foregroundColor(transaction.transactionType == .income ? .green : .red)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(transaction.categoryName)
                                    .font(.body.weight(.medium))
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                
                                if !transaction.memo.isEmpty {
                                    Text(transaction.memo)
                                        .font(.caption)
                                        .foregroundColor(Color("AsaMutedSage"))
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("¥\(Int(transaction.amount))")
                                    .font(.body.weight(.bold))
                                    .foregroundColor(transaction.transactionType == .income ? .green : .red)
                                
                                Text(transaction.date, format: .dateTime.month().day())
                                    .font(.caption)
                                    .foregroundColor(Color("AsaMutedSage"))
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if transaction.id != viewModel.getRecentTransactions().last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
