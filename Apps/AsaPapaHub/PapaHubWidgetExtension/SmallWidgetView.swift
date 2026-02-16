//
//  SmallWidgetView.swift
//  PapaHubWidgetExtension
//
//  systemSmall: スコアリング + 歩数テキスト
//

import SwiftUI
import WidgetKit

// MARK: - SmallWidgetView

/// systemSmall ウィジェットビュー
struct SmallWidgetView: View {
    let data: PapaHubWidgetData

    private let coffeeBrown = Color(red: 0.776, green: 0.549, blue: 0.325)
    private let darkSlate = Color(red: 0.184, green: 0.243, blue: 0.275)
    private let softCream = Color(red: 0.910, green: 0.835, blue: 0.725)

    var body: some View {
        VStack(spacing: 8) {
            // スコアリング
            ZStack {
                Circle()
                    .stroke(softCream, lineWidth: 6)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: CGFloat(data.morningScore) / 100.0)
                    .stroke(coffeeBrown, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(data.morningScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(darkSlate)

                    Text("点")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // 歩数
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.caption2)
                    .foregroundStyle(coffeeBrown)

                Text("\(data.stepsCount)歩")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(darkSlate)
            }

            // 睡眠
            HStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .font(.caption2)
                    .foregroundStyle(coffeeBrown)

                Text("\(String(format: "%.1f", data.sleepHours))h")
                    .font(.caption)
                    .foregroundStyle(darkSlate)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
