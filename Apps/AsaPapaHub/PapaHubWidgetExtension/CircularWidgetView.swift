//
//  CircularWidgetView.swift
//  PapaHubWidgetExtension
//
//  accessoryCircular: Gauge でスコア表示
//

import SwiftUI
import WidgetKit

// MARK: - CircularWidgetView

/// accessoryCircular ウィジェットビュー
struct CircularWidgetView: View {
    let data: PapaHubWidgetData

    var body: some View {
        Gauge(value: Double(data.morningScore), in: 0...100) {
            Image(systemName: "sunrise.fill")
        } currentValueLabel: {
            Text("\(data.morningScore)")
                .font(.headline)
                .fontWeight(.bold)
        }
        .gaugeStyle(.accessoryCircular)
    }
}
