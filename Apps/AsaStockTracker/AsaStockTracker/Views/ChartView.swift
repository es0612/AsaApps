//
//  ChartView.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import Charts

struct ChartView: View {
    let stock: Stock
    @Environment(StockViewModel.self) private var stockViewModel
    @State private var selectedDataPoint: ChartDataPoint?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // チャートヘッダー
            HStack {
                Text("価格チャート")
                    .font(.headline)
                
                Spacer()
                
                if let selectedPoint = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "$%.2f", selectedPoint.price))
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text(formatDate(selectedPoint.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // チャート本体
            if stockViewModel.chartData.isEmpty {
                // サンプルデータまたはローディング表示
                SampleChartView(stock: stock)
            } else {
                RealChartView(
                    data: stockViewModel.chartData,
                    selectedDataPoint: $selectedDataPoint,
                    changeColor: stock.changeColor
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(radius: Constants.UI.shadowRadius)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Real Chart View
struct RealChartView: View {
    let data: [ChartDataPoint]
    @Binding var selectedDataPoint: ChartDataPoint?
    let changeColor: Color
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("時間", point.date),
                y: .value("価格", point.price)
            )
            .foregroundStyle(changeColor.gradient)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("時間", point.date),
                y: .value("価格", point.price)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [changeColor.opacity(0.3), changeColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            if selectedDataPoint?.id == point.id {
                PointMark(
                    x: .value("時間", point.date),
                    y: .value("価格", point.price)
                )
                .foregroundStyle(changeColor)
                .symbolSize(100)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text("$\(String(format: "%.2f", price))")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .onTapGesture { location in
                        // タップ位置から最も近いデータポイントを選択
                        let xPosition = location.x
                        let plotAreaFrame = geometry[chartProxy.plotAreaFrame]
                        let xRange = plotAreaFrame.origin.x...plotAreaFrame.maxX

                        if xRange.contains(xPosition) {
                            let relativeX = (xPosition - plotAreaFrame.origin.x) / plotAreaFrame.width
                            let index = Int(relativeX * CGFloat(data.count))
                            
                            if index >= 0 && index < data.count {
                                selectedDataPoint = data[index]
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Sample Chart View
struct SampleChartView: View {
    let stock: Stock
    
    var body: some View {
        let sampleData = generateSampleData(for: stock)
        
        Chart(sampleData) { point in
            LineMark(
                x: .value("時間", point.date),
                y: .value("価格", point.price)
            )
            .foregroundStyle(stock.changeColor.gradient)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("時間", point.date),
                y: .value("価格", point.price)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [stock.changeColor.opacity(0.3), stock.changeColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text("$\(String(format: "%.2f", price))")
                            .font(.caption2)
                    }
                }
            }
        }
    }
    
    private func generateSampleData(for stock: Stock) -> [ChartDataPoint] {
        var data: [ChartDataPoint] = []
        let now = Date()
        let basePrice = stock.previousClose
        
        for i in 0..<50 {
            let date = now.addingTimeInterval(TimeInterval(-i * 300))  // 5分間隔
            let randomChange = Double.random(in: -2...2)
            let price = basePrice + (randomChange * Double(50 - i) / 50.0)
            
            data.append(ChartDataPoint(
                date: date,
                price: price,
                volume: Int.random(in: 100000...1000000)
            ))
        }
        
        return data.reversed()
    }
}

// MARK: - Preview
#Preview {
    ChartView(
        stock: Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 175.43,
            previousClose: 173.50,
            change: 1.93,
            changePercent: 1.11,
            volume: 52_345_678
        )
    )
    .environment(StockViewModel())
    .padding()
}