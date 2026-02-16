//
//  RectangularWidgetView.swift
//  PapaHubWidgetExtension
//
//  accessoryRectangular: ブリーフィング要約テキスト
//

import SwiftUI
import WidgetKit

// MARK: - RectangularWidgetView

/// accessoryRectangular ウィジェットビュー
struct RectangularWidgetView: View {
    let data: PapaHubWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "sunrise.fill")
                    .font(.caption2)

                Text("今日のブリーフィング")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }

            if let summary = data.briefingSummary {
                Text(summary)
                    .font(.caption2)
                    .lineLimit(2)
            } else {
                Text("スコア: \(data.morningScore)点 | \(data.stepsCount)歩")
                    .font(.caption2)
            }
        }
    }
}
