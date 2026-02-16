//
//  LargeWidgetView.swift
//  PapaHubWidgetExtension
//
//  systemLarge: スコア + 簡易グラフ + 次のルーティンアイテム
//

import SwiftUI
import WidgetKit

// MARK: - LargeWidgetView

/// systemLarge ウィジェットビュー
struct LargeWidgetView: View {
    let data: PapaHubWidgetData

    private let coffeeBrown = Color(red: 0.776, green: 0.549, blue: 0.325)
    private let darkSlate = Color(red: 0.184, green: 0.243, blue: 0.275)
    private let softCream = Color(red: 0.910, green: 0.835, blue: 0.725)
    private let mutedSage = Color(red: 0.478, green: 0.569, blue: 0.553)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー: スコア + 日付
            headerSection

            // ドメインスコアバー
            domainScoreSection

            Divider()

            // ルーティンアイテム
            routineSection

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            // スコアリング
            ZStack {
                Circle()
                    .stroke(softCream, lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: CGFloat(data.morningScore) / 100.0)
                    .stroke(coffeeBrown, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(data.morningScore)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(darkSlate)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("朝活スコア")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(darkSlate)

                HStack(spacing: 10) {
                    Label("\(data.stepsCount)歩", systemImage: "figure.walk")
                    Label("\(String(format: "%.1f", data.sleepHours))h", systemImage: "moon.fill")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(data.date, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var domainScoreSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ドメインスコア")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            let domains = data.domainScores.isEmpty
                ? PapaHubWidgetData.placeholder.domainScores
                : data.domainScores

            ForEach(domains) { domain in
                HStack(spacing: 8) {
                    Image(systemName: domain.icon)
                        .font(.caption2)
                        .foregroundStyle(coffeeBrown)
                        .frame(width: 16)

                    Text(domain.domain)
                        .font(.caption2)
                        .foregroundStyle(darkSlate)
                        .frame(width: 30, alignment: .leading)

                    // プログレスバー
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(softCream)
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(coffeeBrown)
                                .frame(width: geo.size.width * CGFloat(domain.score) / 100.0, height: 6)
                        }
                    }
                    .frame(height: 6)

                    Text("\(domain.score)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(darkSlate)
                        .frame(width: 24, alignment: .trailing)
                }
            }
        }
    }

    private var routineSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今日のルーティン")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            let items = data.routineItems.isEmpty
                ? PapaHubWidgetData.placeholder.routineItems
                : data.routineItems

            ForEach(items) { item in
                HStack(spacing: 8) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(item.isCompleted ? .green : mutedSage)

                    Image(systemName: item.icon)
                        .font(.caption2)
                        .foregroundStyle(coffeeBrown)

                    Text(item.title)
                        .font(.caption)
                        .foregroundStyle(item.isCompleted ? .secondary : darkSlate)
                        .strikethrough(item.isCompleted)
                }
            }
        }
    }
}
