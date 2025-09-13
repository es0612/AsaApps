//
//  MarketOverviewView.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import SwiftUI

struct MarketOverviewView: View {
    @Environment(StockViewModel.self) private var stockViewModel
    @State private var selectedMarket = 0
    
    let markets = ["米国", "日本", "欧州", "アジア"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // マーケット選択
                Picker("マーケット", selection: $selectedMarket) {
                    ForEach(0..<markets.count, id: \.self) { index in
                        Text(markets[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // 主要指数
                MarketIndicesView()
                
                // トップ銘柄
                TopStocksView()
                    .environment(stockViewModel)
                
                // マーケットニュース（プレースホルダー）
                MarketNewsView()
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Market Indices View
struct MarketIndicesView: View {
    let indices = [
        ("S&P 500", 4783.45, 15.29, 0.32),
        ("ダウ平均", 37689.54, 134.58, 0.36),
        ("NASDAQ", 15011.35, -43.89, -0.29),
        ("日経225", 33753.33, 225.85, 0.67)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("主要指数")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(indices, id: \.0) { index in
                        IndexCard(
                            name: index.0,
                            value: index.1,
                            change: index.2,
                            changePercent: index.3
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Index Card
struct IndexCard: View {
    let name: String
    let value: Double
    let change: Double
    let changePercent: Double
    
    var changeColor: Color {
        change >= 0 ? .green : .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.2f", value))
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 4) {
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                
                Text(String(format: "%.2f", abs(change)))
                    .font(.caption)
                
                Text(String(format: "(%.2f%%)", abs(changePercent)))
                    .font(.caption)
            }
            .foregroundColor(changeColor)
        }
        .padding()
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
}

// MARK: - Top Stocks View
struct TopStocksView: View {
    @Environment(StockViewModel.self) private var stockViewModel
    
    var topGainers: [Stock] {
        stockViewModel.stocks
            .filter { $0.changePercent > 0 }
            .sorted { $0.changePercent > $1.changePercent }
            .prefix(5)
            .map { $0 }
    }
    
    var topLosers: [Stock] {
        stockViewModel.stocks
            .filter { $0.changePercent < 0 }
            .sorted { $0.changePercent < $1.changePercent }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 値上がり銘柄
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                    Text("値上がり上位")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                ForEach(topGainers) { stock in
                    MiniStockRow(stock: stock)
                        .padding(.horizontal)
                }
            }
            
            // 値下がり銘柄
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                    Text("値下がり上位")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                ForEach(topLosers) { stock in
                    MiniStockRow(stock: stock)
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Mini Stock Row
struct MiniStockRow: View {
    let stock: Stock
    
    var body: some View {
        HStack {
            Text(stock.symbol)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(stock.formattedPrice)
                .font(.subheadline)
            
            Text(stock.formattedChangePercent)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stock.changeColor.opacity(0.15))
                )
                .foregroundColor(stock.changeColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Market News View
struct MarketNewsView: View {
    let sampleNews = [
        ("FRB、金利据え置きを決定", "2時間前"),
        ("テック企業の決算シーズン開始", "4時間前"),
        ("日経平均、年初来高値を更新", "6時間前"),
        ("原油価格が3ヶ月ぶりの高値", "8時間前")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "newspaper")
                    .foregroundColor(Color(red: 0.776, green: 0.549, blue: 0.325))  // AsaCoffeeBrown
                Text("マーケットニュース")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(sampleNews, id: \.0) { news in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(news.0)
                                .font(.subheadline)
                                .lineLimit(2)
                            
                            Text(news.1)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MarketOverviewView()
            .environment(StockViewModel())
            .navigationTitle("マーケット")
    }
}