//
//  ContentView.swift
//  AsaCurrencyConverter
//  
//  Created on 2025/07/15
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var history: [ConversionHistory]
    @State private var currencyService = CurrencyService.shared
    
    @State private var fromCurrency = "USD"
    @State private var toCurrency = "JPY"
    @State private var amount: String = ""
    @State private var convertedAmount: Double = 0.0
    @State private var exchangeRate: Double = 0.0
    @State private var showingCurrencyPicker = false
    @State private var isSelectingFromCurrency = true
    @State private var lastUpdateTime: Date?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // タイトル
                    Text("為替レート変換")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    // 変換メインカード
                    AsaCard {
                        VStack(spacing: 20) {
                            // 変換元通貨
                            HStack {
                                Text("変換元")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Spacer()
                                Button(action: {
                                    isSelectingFromCurrency = true
                                    showingCurrencyPicker = true
                                }) {
                                    HStack {
                                        Text(CurrencyData.getCurrencySymbol(by: fromCurrency))
                                        Text(fromCurrency)
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color("AsaSoftCream"))
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // 金額入力
                            TextField("金額を入力", text: $amount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.title2)
                            
                            // 変換先通貨
                            HStack {
                                Text("変換先")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Spacer()
                                Button(action: {
                                    isSelectingFromCurrency = false
                                    showingCurrencyPicker = true
                                }) {
                                    HStack {
                                        Text(CurrencyData.getCurrencySymbol(by: toCurrency))
                                        Text(toCurrency)
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color("AsaSoftCream"))
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // 変換結果
                            if convertedAmount > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("変換結果")
                                        .font(.headline)
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                    
                                    HStack {
                                        Text(String(format: "%.2f", convertedAmount))
                                            .font(.title.bold())
                                        Text(CurrencyData.getCurrencySymbol(by: toCurrency))
                                        Spacer()
                                    }
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                    
                                    Text("1 \(fromCurrency) = \(String(format: "%.4f", exchangeRate)) \(toCurrency)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color("AsaSoftCream").opacity(0.5))
                                .cornerRadius(10)
                            }
                            
                            // 変換ボタン
                            AsaButton(
                                title: currencyService.isLoading ? "変換中..." : "変換",
                                action: performConversion,
                                color: Color("AsaCoffeeBrown"),
                                isEnabled: !currencyService.isLoading && !amount.isEmpty
                            )
                        }
                    }
                    
                    // エラーメッセージ
                    if let errorMessage = currencyService.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 最終更新時刻
                    if let lastUpdate = currencyService.lastUpdateTime {
                        Text("最終更新: \(lastUpdate.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 履歴
                    if !history.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("変換履歴")
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            ForEach(history.prefix(5).reversed(), id: \.timestamp) { record in
                                AsaCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(String(format: "%.2f", record.amount)) \(record.fromCurrency) → \(String(format: "%.2f", record.convertedAmount)) \(record.toCurrency)")
                                                .font(.body.bold())
                                            Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text("1:\(String(format: "%.4f", record.rate))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCurrencyPicker) {
                CurrencyPickerView(
                    selectedCurrency: isSelectingFromCurrency ? $fromCurrency : $toCurrency,
                    isPresented: $showingCurrencyPicker
                )
            }
        }
    }
    
    private func performConversion() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        currencyService.clearError()
        
        Task {
            do {
                let result = try await currencyService.convertCurrency(
                    amount: amountValue,
                    from: fromCurrency,
                    to: toCurrency
                )
                
                await MainActor.run {
                    convertedAmount = result.convertedAmount
                    exchangeRate = result.rate
                    
                    // 履歴に保存
                    let historyRecord = ConversionHistory(
                        fromCurrency: fromCurrency,
                        toCurrency: toCurrency,
                        amount: amountValue,
                        convertedAmount: result.convertedAmount,
                        rate: result.rate
                    )
                    modelContext.insert(historyRecord)
                    
                    try? modelContext.save()
                }
            } catch {
                print("変換エラー: \(error)")
            }
        }
    }
}

// MARK: - Currency Picker View
struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return CurrencyData.popularCurrencies
        }
        return CurrencyData.popularCurrencies.filter { currency in
            currency.name.localizedCaseInsensitiveContains(searchText) ||
            currency.id.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredCurrencies) { currency in
                Button(action: {
                    selectedCurrency = currency.id
                    isPresented = false
                }) {
                    HStack {
                        Text(currency.symbol)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(currency.id)
                                .font(.headline)
                            Text(currency.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if currency.id == selectedCurrency {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .searchable(text: $searchText, prompt: "通貨を検索")
            .navigationTitle("通貨選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ConversionHistory.self, inMemory: true)
}
