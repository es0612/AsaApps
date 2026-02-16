//
//  PapaHubWidget.swift
//  PapaHubWidgetExtension
//
//  パパハブウィジェットバンドル
//  systemSmall/Medium/Large + ロック画面 + Live Activity
//

import WidgetKit
import SwiftUI

// MARK: - PapaHubWidgetBundle

/// パパハブウィジェットバンドル
@main
struct PapaHubWidgetBundle: WidgetBundle {
    var body: some Widget {
        PapaHubWidget()
        PapaHubLockScreenWidget()
        MorningRoutineLiveActivity()
    }
}

// MARK: - PapaHubWidget

/// メインウィジェット（systemSmall / systemMedium / systemLarge）
struct PapaHubWidget: Widget {
    let kind = "PapaHubWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PapaHubWidgetProvider()) { entry in
            PapaHubWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AsaPapaHub")
        .description("朝活スコアとライフドメインの状況を表示します")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - PapaHubLockScreenWidget

/// ロック画面ウィジェット（accessoryCircular / accessoryRectangular）
struct PapaHubLockScreenWidget: Widget {
    let kind = "PapaHubLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PapaHubWidgetProvider()) { entry in
            PapaHubLockScreenEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AsaPapaHub ロック画面")
        .description("朝活スコアをロック画面に表示します")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - PapaHubWidgetEntryView

/// ウィジェットエントリービュー（サイズ分岐）
struct PapaHubWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PapaHubWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - PapaHubLockScreenEntryView

/// ロック画面ウィジェットエントリービュー
struct PapaHubLockScreenEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PapaHubWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularWidgetView(data: entry.data)
        case .accessoryRectangular:
            RectangularWidgetView(data: entry.data)
        default:
            CircularWidgetView(data: entry.data)
        }
    }
}
