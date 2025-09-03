import WidgetKit
import SwiftUI

// MARK: - Quote Widget Bundle
@main
struct QuoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuoteWidget()
    }
}

// MARK: - Widget Extensions
extension WidgetFamily {
    var displayName: String {
        switch self {
        case .systemSmall:
            return "小"
        case .systemMedium:
            return "中"
        case .systemLarge:
            return "大"
        default:
            return "不明"
        }
    }
}

// MARK: - Color Extensions for Widget
extension Color {
    /// ウィジェット用のカラーヘルパー
    static func widgetColor(named name: String) -> Color {
        return Color(name)
    }
}

// MARK: - Date Extensions for Widget
extension Date {
    /// ウィジェット表示用の時刻フォーマット
    var widgetTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
    
    /// ウィジェット表示用の日付フォーマット
    var widgetDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension QuoteEntry {
    /// プレビュー用のサンプルエントリー
    static var sampleEntries: [QuoteEntry] {
        let sampleQuotes = [
            Quote(text: "今日という日は、残りの人生の最初の日である", author: "アビー・ホフマン", category: .encouragement),
            Quote(text: "成功とは、準備と機会が出会うところに生まれる", author: "ボビー・ナイト", category: .success),
            Quote(text: "家族は人生で最も大切な宝物である", author: "不明", category: .family),
            Quote(text: "早起きは三文の徳", author: "日本のことわざ", category: .morningActivity),
            Quote(text: "仕事に愛情を持てば、人生が楽しくなる", author: "不明", category: .work),
            Quote(text: "昨日の自分を超えることが、真の勝利である", author: "不明", category: .personal)
        ]
        
        return sampleQuotes.enumerated().map { index, quote in
            QuoteEntry(
                date: Calendar.current.date(byAdding: .hour, value: index, to: Date()) ?? Date(),
                quote: quote
            )
        }
    }
}
#endif