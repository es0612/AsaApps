//
//  StockRowView.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import SwiftUI

struct StockRowView: View {
    let stock: Stock
    let isFavorite: Bool
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 銘柄情報
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stock.symbol)
                        .font(.headline)
                        .fontWeight(.semibold)

                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }

                Text(stock.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // データソース表示
                Text(stock.dataSourceLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            Spacer()
            
            // 価格情報
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.formattedPrice)
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text(stock.formattedChange)
                        .font(.caption)
                    
                    Text(stock.formattedChangePercent)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(stock.changeColor.opacity(0.15))
                        )
                }
                .foregroundColor(stock.changeColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isAnimating ? stock.changeColor.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
        .onAppear {
            // 価格更新時のアニメーション
            withAnimation(.easeInOut(duration: 0.5)) {
                isAnimating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAnimating = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    List {
        StockRowView(
            stock: Stock(
                symbol: "AAPL",
                name: "Apple Inc.",
                currentPrice: 175.43,
                previousClose: 173.50,
                change: 1.93,
                changePercent: 1.11,
                volume: 52_345_678
            ),
            isFavorite: true
        )
        
        StockRowView(
            stock: Stock(
                symbol: "GOOGL",
                name: "Alphabet Inc.",
                currentPrice: 139.76,
                previousClose: 141.23,
                change: -1.47,
                changePercent: -1.04,
                volume: 21_456_789
            ),
            isFavorite: false
        )
    }
    .listStyle(InsetGroupedListStyle())
}