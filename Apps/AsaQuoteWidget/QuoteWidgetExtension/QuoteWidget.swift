import WidgetKit
import SwiftUI

// MARK: - Quote Widget
struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("名言ウィジェット")
        .description("励ましの名言を表示するウィジェットです")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Quote Widget Entry View
struct QuoteWidgetEntryView: View {
    let entry: QuoteEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallQuoteView(entry: entry)
            case .systemMedium:
                MediumQuoteView(entry: entry)
            case .systemLarge:
                LargeQuoteView(entry: entry)
            default:
                SmallQuoteView(entry: entry)
            }
        }
    }
}

// MARK: - Small Quote View
struct SmallQuoteView: View {
    let entry: QuoteEntry
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: [
                        Color("AsaSoftCream"),
                        Color("AsaMutedSage").opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 4) {
                    // カテゴリ
                    HStack {
                        Text(entry.quote.category.emoji)
                            .font(.caption)
                        Spacer()
                        Text(entry.quote.category.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    Spacer(minLength: 2)
                    
                    // 名言テキスト
                    Text(entry.quote.text)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                    
                    Spacer(minLength: 2)
                    
                    // 作者
                    Text("— \(entry.quote.author)")
                        .font(.caption2)
                        .foregroundColor(Color("AsaMutedSage"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(12)
            }
        }
        .containerBackground(for: .widget) {
            Color("AsaSoftCream")
        }
    }
}

// MARK: - Medium Quote View
struct MediumQuoteView: View {
    let entry: QuoteEntry
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: [
                        Color("AsaSoftCream"),
                        Color("AsaMutedSage").opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                HStack(spacing: 16) {
                    // 左側：カテゴリアイコンエリア
                    VStack(spacing: 8) {
                        Text(entry.quote.category.emoji)
                            .font(.largeTitle)
                        
                        Text(entry.quote.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaMutedSage"))
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 80)
                    
                    // 右側：名言エリア
                    VStack(alignment: .leading, spacing: 8) {
                        Spacer()
                        
                        Text(entry.quote.text)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.8)
                        
                        HStack {
                            Spacer()
                            Text("— \(entry.quote.author)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                        
                        Spacer()
                    }
                }
                .padding(16)
            }
        }
        .containerBackground(for: .widget) {
            Color("AsaSoftCream")
        }
    }
}

// MARK: - Large Quote View
struct LargeQuoteView: View {
    let entry: QuoteEntry
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: [
                        Color("AsaSoftCream").opacity(0.8),
                        Color("AsaMutedSage").opacity(0.3),
                        Color("AsaCoffeeBrown").opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 20) {
                    // 上部：カテゴリ情報
                    HStack {
                        HStack(spacing: 8) {
                            Text(entry.quote.category.emoji)
                                .font(.title2)
                            Text(entry.quote.category.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("AsaCoffeeBrown"))
                        )
                        
                        Spacer()
                        
                        // 現在時刻
                        Text(entry.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    Spacer()
                    
                    // 中央：名言メイン
                    VStack(spacing: 16) {
                        // 開始引用符
                        HStack {
                            Text("\u{201C}")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(Color("AsaCoffeeBrown").opacity(0.4))
                            Spacer()
                        }
                        
                        // 名言テキスト
                        Text(entry.quote.text)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .lineLimit(4)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .minimumScaleFactor(0.7)
                        
                        // 終了引用符
                        HStack {
                            Spacer()
                            Text("\u{201D}")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(Color("AsaCoffeeBrown").opacity(0.4))
                        }
                    }
                    
                    Spacer()
                    
                    // 下部：作者とフッター
                    VStack(spacing: 8) {
                        // 区切り線
                        Rectangle()
                            .fill(Color("AsaMutedSage").opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 40)
                        
                        // 作者
                        Text("— \(entry.quote.author)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        // フッター
                        Text("朝活パパエンジニア")
                            .font(.caption2)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }
                .padding(20)
            }
        }
        .containerBackground(for: .widget) {
            Color("AsaSoftCream")
        }
    }
}

// MARK: - Previews
#if DEBUG
struct QuoteWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QuoteWidgetEntryView(entry: QuoteEntry(
                date: Date(),
                quote: Quote(
                    text: "今日という日は、残りの人生の最初の日である",
                    author: "アビー・ホフマン",
                    category: .encouragement
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            QuoteWidgetEntryView(entry: QuoteEntry(
                date: Date(),
                quote: Quote(
                    text: "成功とは、準備と機会が出会うところに生まれる",
                    author: "ボビー・ナイト",
                    category: .success
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            QuoteWidgetEntryView(entry: QuoteEntry(
                date: Date(),
                quote: Quote(
                    text: "家族は人生で最も大切な宝物である",
                    author: "不明",
                    category: .family
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
#endif