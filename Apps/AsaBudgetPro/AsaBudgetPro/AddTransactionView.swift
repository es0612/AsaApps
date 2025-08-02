//
//  AddTransactionView.swift
//  AsaBudgetPro
//  
//  Created on 2025/08/03
//

import SwiftUI

struct AddTransactionView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTransactionType: TransactionType = .expense
    
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
                        headerView
                        
                        transactionTypeSelector
                        
                        formView
                        
                        actionButtons
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                setupInitialState()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("取引を追加")
                .font(.title.weight(.bold))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text("収入または支出を記録します")
                .font(.subheadline)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .padding(.top)
    }
    
    private var transactionTypeSelector: some View {
        AsaCard {
            VStack(spacing: 12) {
                Text("取引種別")
                    .font(.headline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Picker("取引種別", selection: $selectedTransactionType) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.rawValue)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedTransactionType) { oldValue, newValue in
                    viewModel.selectedTransactionType = newValue
                    updateSelectedCategory()
                }
            }
        }
    }
    
    private var formView: some View {
        AsaCard {
            VStack(spacing: 16) {
                // カテゴリ選択
                categorySelector
                
                // 金額入力
                amountInput
                
                // 日付選択
                dateSelector
                
                // メモ入力
                memoInput
            }
        }
    }
    
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カテゴリ")
                .font(.body.weight(.medium))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            let availableCategories = viewModel.getCategoriesForType(selectedTransactionType)
            
            if availableCategories.isEmpty {
                Text("カテゴリがありません")
                    .font(.body)
                    .foregroundColor(Color("AsaMutedSage"))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(availableCategories, id: \.id) { category in
                            CategoryCard(
                                category: category,
                                isSelected: viewModel.selectedCategory?.id == category.id
                            ) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var amountInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("金額")
                .font(.body.weight(.medium))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            HStack {
                Text("¥")
                    .font(.title2.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                TextField("0", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
                    .font(.title2.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .onChange(of: viewModel.amount) { _, _ in
                        viewModel.validateAmount()
                    }
            }
            .padding()
            .background(Color.white.opacity(0.5))
            .cornerRadius(8)
            
            if let error = viewModel.amountError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var dateSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("日付")
                .font(.body.weight(.medium))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            DatePicker(
                "取引日付",
                selection: $viewModel.transactionDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .foregroundColor(Color("AsaCoffeeBrown"))
        }
    }
    
    private var memoInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ（任意）")
                .font(.body.weight(.medium))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            TextField("詳細を入力...", text: $viewModel.memo)
                .font(.body)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(8)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            AsaButton(
                title: "追加",
                action: addTransaction,
                color: Color("AsaCoffeeBrown"),
                isEnabled: canAddTransaction
            )
            
            Button("キャンセル") {
                dismiss()
            }
            .font(.body.weight(.medium))
            .foregroundColor(Color("AsaMutedSage"))
        }
    }
    
    private var canAddTransaction: Bool {
        guard let amount = Double(viewModel.amount), amount > 0,
              viewModel.selectedCategory != nil else {
            return false
        }
        return viewModel.amountError == nil
    }
    
    private func setupInitialState() {
        viewModel.selectedTransactionType = selectedTransactionType
        updateSelectedCategory()
    }
    
    private func updateSelectedCategory() {
        let categories = viewModel.getCategoriesForType(selectedTransactionType)
        viewModel.selectedCategory = categories.first
    }
    
    private func addTransaction() {
        viewModel.addTransaction()
        dismiss()
    }
}

struct CategoryCard: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color(hex: category.colorHex))
                
                Text(category.name)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? .white : Color("AsaCoffeeBrown"))
                    .lineLimit(1)
            }
            .padding()
            .frame(width: 80, height: 80)
            .background(
                isSelected ? Color(hex: category.colorHex) : Color.white.opacity(0.7)
            )
            .cornerRadius(12)
            .shadow(radius: isSelected ? 4 : 1)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    AddTransactionView(viewModel: BudgetViewModel())
}