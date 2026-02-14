import WidgetKit
import SwiftUI

// MARK: - LifeLogWidgetBundle

/// ライフログウィジェットバンドル
@main
struct LifeLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        LifeLogWidget()
        LifeLogLockScreenWidget()
    }
}

// MARK: - LifeLogWidget

/// メインウィジェット（systemSmall / systemMedium / systemLarge）
struct LifeLogWidget: Widget {
    let kind = "LifeLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifeLogWidgetProvider()) { entry in
            LifeLogWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AsaLifeLog")
        .description("今日のライフログサマリーを表示します")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - LifeLogLockScreenWidget

/// ロック画面ウィジェット（accessoryCircular / accessoryRectangular）
struct LifeLogLockScreenWidget: Widget {
    let kind = "LifeLogLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifeLogWidgetProvider()) { entry in
            LifeLogLockScreenEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AsaLifeLog ロック画面")
        .description("朝活スコアや歩数をロック画面に表示します")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - WidgetEntryView

/// ウィジェットエントリービュー（サイズ分岐）
struct LifeLogWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LifeLogWidgetEntry

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

/// ロック画面ウィジェットエントリービュー
struct LifeLogLockScreenEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LifeLogWidgetEntry

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
