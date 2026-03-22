//
//  WeeklyChartView.swift
//  AsaLanguageLearn
//
//  週間学習チャート
//

import AsaUIKit
import Charts
import SwiftUI

struct WeeklyChartView: View {
    let data: [DailyStats]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今週の学習")
                .font(.headline)

            if data.isEmpty {
                emptyState
            } else {
                chartView
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("まだデータがありません")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
    }

    private var chartView: some View {
        VStack(spacing: 16) {
            // バーチャート
            Chart(data) { stat in
                BarMark(
                    x: .value("Day", stat.dayOfWeek),
                    y: .value("Items", stat.itemsPracticed)
                )
                .foregroundStyle(
                    stat.isToday
                        ? AsaColors.coffeeBrown
                        : AsaColors.coffeeBrown.opacity(0.5)
                )
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading)
            }

            // サマリー
            HStack(spacing: 20) {
                WeekStat(
                    title: "合計",
                    value: "\(data.reduce(0) { $0 + $1.itemsPracticed })",
                    unit: "フレーズ"
                )

                WeekStat(
                    title: "平均正解率",
                    value: String(format: "%.0f%%", averageCorrectRate * 100),
                    unit: ""
                )

                WeekStat(
                    title: "学習日数",
                    value: "\(studyDays)",
                    unit: "日"
                )
            }
        }
    }

    private var averageCorrectRate: Double {
        let totalItems = data.reduce(0) { $0 + $1.itemsPracticed }
        let totalCorrect = data.reduce(0) { $0 + $1.correctCount }
        guard totalItems > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalItems)
    }

    private var studyDays: Int {
        data.filter { $0.itemsPracticed > 0 }.count
    }
}

// MARK: - Week Stat

struct WeekStat: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let sampleData: [DailyStats] = (0..<7).map { offset in
        let date = Calendar.current.date(byAdding: .day, value: -6 + offset, to: Date())!
        return DailyStats(
            date: date,
            itemsPracticed: Int.random(in: 0...15),
            correctCount: Int.random(in: 0...12),
            studyDurationSeconds: Int.random(in: 0...600),
            averageScore: Double.random(in: 0.6...0.95)
        )
    }

    VStack {
        WeeklyChartView(data: sampleData)
            .padding()

        WeeklyChartView(data: [])
            .padding()
    }
}
