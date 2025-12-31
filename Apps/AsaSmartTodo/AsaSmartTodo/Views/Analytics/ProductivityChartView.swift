//
//  ProductivityChartView.swift
//  AsaSmartTodo
//
//  24時間生産性チャート
//  タスク作成数と完了率を時間帯別に可視化
//

import SwiftUI
import Charts
import AsaUIKit

struct ProductivityChartView: View {
    let hourlyData: [HourlyData]

    @State private var selectedHour: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(AsaColors.mutedSage)

                Text("24時間の生産性")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            // 朝活ハイライト
            earlyMorningHighlight

            // チャート
            Chart {
                ForEach(hourlyData) { data in
                    // タスク作成数（Bar）
                    BarMark(
                        x: .value("時間", data.hour),
                        y: .value("作成数", data.tasksCreated)
                    )
                    .foregroundStyle(
                        data.hour >= 5 && data.hour < 7
                            ? AsaColors.coffeeBrown.gradient
                            : AsaColors.mutedSage.gradient
                    )
                    .opacity(selectedHour == nil || selectedHour == data.hour ? 1.0 : 0.3)

                    // 完了率（Line）
                    LineMark(
                        x: .value("時間", data.hour),
                        y: .value("完了率", data.completionRate * 100)
                    )
                    .foregroundStyle(AsaColors.mocha)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(Circle())
                    .opacity(selectedHour == nil || selectedHour == data.hour ? 1.0 : 0.3)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { value in
                    if let hour = value.as(Int.self) {
                        AxisValueLabel {
                            Text("\(hour)時")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .bottom, spacing: 12) {
                HStack(spacing: 16) {
                    // 作成数凡例
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AsaColors.mutedSage)
                            .frame(width: 12, height: 12)

                        Text("作成数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // 完了率凡例
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AsaColors.mocha)
                            .frame(width: 12, height: 12)

                        Text("完了率(%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartXSelection(value: $selectedHour)

            // 選択時の詳細表示
            if let selected = selectedHour, let data = hourlyData.first(where: { $0.hour == selected }) {
                selectedHourDetail(data)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Early Morning Highlight

    private var earlyMorningHighlight: some View {
        let morningData = hourlyData.filter { $0.hour >= 5 && $0.hour < 7 }
        let totalCreated = morningData.reduce(0) { $0 + $1.tasksCreated }
        let avgCompletionRate = morningData.isEmpty ? 0.0 :
            morningData.reduce(0.0) { $0 + $1.completionRate } / Double(morningData.count)

        return HStack(spacing: 12) {
            Image(systemName: "sunrise.fill")
                .font(.title3)
                .foregroundColor(AsaColors.coffeeBrown)

            VStack(alignment: .leading, spacing: 4) {
                Text("朝活時間帯（5:00-7:00）")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AsaColors.coffeeBrown)

                HStack(spacing: 12) {
                    Text("作成: \(totalCreated)件")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("完了率: \(Int(avgCompletionRate * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(AsaColors.coffeeBrown.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Selected Hour Detail

    private func selectedHourDetail(_ data: HourlyData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(data.hour)時のデータ")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AsaColors.darkSlate)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("タスク作成")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(data.tasksCreated)件")
                        .font(.headline)
                        .foregroundColor(AsaColors.mutedSage)
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text("完了率")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(Int(data.completionRate * 100))%")
                        .font(.headline)
                        .foregroundColor(AsaColors.mocha)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedHour = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(AsaColors.darkSlate.opacity(0.05))
        .cornerRadius(8)
    }
}

