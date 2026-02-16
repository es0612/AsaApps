//
//  MediumWidgetView.swift
//  PapaHubWidgetExtension
//
//  systemMedium: ScoreRing + 6ドメインアイコン・スコア
//

import SwiftUI
import WidgetKit

// MARK: - MediumWidgetView

/// systemMedium ウィジェットビュー
struct MediumWidgetView: View {
    let data: PapaHubWidgetData

    private let coffeeBrown = Color(red: 0.776, green: 0.549, blue: 0.325)
    private let darkSlate = Color(red: 0.184, green: 0.243, blue: 0.275)
    private let softCream = Color(red: 0.910, green: 0.835, blue: 0.725)

    var body: some View {
        HStack(spacing: 16) {
            // 左: スコアリング
            scoreRing

            // 右: 6ドメインスコア
            domainGrid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Subviews

    private var scoreRing: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(softCream, lineWidth: 5)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: CGFloat(data.morningScore) / 100.0)
                    .stroke(coffeeBrown, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text("\(data.morningScore)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(darkSlate)
            }

            Text("朝活スコア")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var domainGrid: some View {
        VStack(spacing: 6) {
            let domains = data.domainScores.isEmpty
                ? PapaHubWidgetData.placeholder.domainScores
                : data.domainScores

            // 3列 x 2行
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { col in
                        let index = row * 3 + col
                        if index < domains.count {
                            domainItem(domains[index])
                        }
                    }
                }
            }
        }
    }

    private func domainItem(_ domain: DomainScore) -> some View {
        VStack(spacing: 2) {
            Image(systemName: domain.icon)
                .font(.caption2)
                .foregroundStyle(coffeeBrown)

            Text("\(domain.score)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(darkSlate)
        }
        .frame(width: 44)
    }
}
