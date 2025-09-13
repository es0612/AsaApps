//
//  StockDetailView.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import Charts

struct StockDetailView: View {
    let stock: Stock
    @Environment(StockViewModel.self) private var stockViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoadingChart = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 価格情報ヘッダー
                    PriceHeaderView(stock: stock)
                    
                    // チャート
                    ChartView(stock: stock)
                        .frame(height: 250)
                        .padding(.horizontal)
                    
                    // 詳細情報
                    DetailInfoView(stock: stock)
                    
                    // 統計情報
                    StatisticsView(stock: stock)
                }
                .padding(.vertical)
            }
            .navigationTitle(stock.symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadChartData()
        }
    }
    
    private func loadChartData() {
        isLoadingChart = true
        Task {
            await stockViewModel.fetchChartData(for: stock)
            isLoadingChart = false
        }
    }
}

// MARK: - Price Header View
struct PriceHeaderView: View {
    let stock: Stock
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(stock.symbol)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stock.formattedPrice)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Text(stock.formattedChange)
                            .font(.headline)
                        
                        Text(stock.formattedChangePercent)
                            .font(.headline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(stock.changeColor.opacity(0.15))
                            )
                    }
                    .foregroundColor(stock.changeColor)
                }
            }
            
            Divider()
        }
        .padding(.horizontal)
    }
}

// MARK: - Detail Info View
struct DetailInfoView: View {
    let stock: Stock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基本情報")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                InfoRow(title: "前日終値", value: String(format: "$%.2f", stock.previousClose))
                InfoRow(title: "出来高", value: stock.formattedVolume)
                
                if let marketCap = stock.formattedMarketCap {
                    InfoRow(title: "時価総額", value: marketCap)
                }
                
                InfoRow(title: "最終更新", value: formatDate(stock.lastUpdated))
            }
            .padding(.horizontal)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Statistics View
struct StatisticsView: View {
    let stock: Stock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("統計情報")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if let high52Week = stock.high52Week {
                    InfoRow(title: "52週高値", value: String(format: "$%.2f", high52Week))
                }
                
                if let low52Week = stock.low52Week {
                    InfoRow(title: "52週安値", value: String(format: "$%.2f", low52Week))
                }
                
                // 52週レンジ表示
                if let high = stock.high52Week, let low = stock.low52Week {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("52週レンジ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        GeometryReader { geometry in
                            let range = high - low
                            let currentPosition = (stock.currentPrice - low) / range
                            
                            ZStack(alignment: .leading) {
                                // 背景バー
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 8)
                                
                                // 現在価格の位置
                                Circle()
                                    .fill(Color(red: 0.776, green: 0.549, blue: 0.325))  // AsaCoffeeBrown
                                    .frame(width: 16, height: 16)
                                    .offset(x: geometry.size.width * CGFloat(currentPosition) - 8)
                            }
                        }
                        .frame(height: 16)
                        
                        HStack {
                            Text(String(format: "$%.2f", low))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(String(format: "$%.2f", high))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
#Preview {
    StockDetailView(
        stock: Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 175.43,
            previousClose: 173.50,
            change: 1.93,
            changePercent: 1.11,
            volume: 52_345_678,
            marketCap: 2_720_000_000_000,
            high52Week: 198.23,
            low52Week: 124.17
        )
    )
    .environment(StockViewModel())
}