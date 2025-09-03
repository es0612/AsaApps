import WidgetKit
import SwiftUI

// MARK: - Quote Timeline Entry
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
}

// MARK: - Quote Provider
struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        let placeholderQuote = Quote(
            text: "今日という日は、残りの人生の最初の日である",
            author: "アビー・ホフマン",
            category: .encouragement
        )
        return QuoteEntry(date: Date(), quote: placeholderQuote)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> ()) {
        let sharedDefaults = SharedDefaults.shared
        
        let quote: Quote
        if let lastDisplayedQuote = sharedDefaults.lastDisplayedQuote {
            quote = lastDisplayedQuote
        } else {
            quote = sharedDefaults.getQuoteForWidget()
        }
        
        completion(QuoteEntry(date: Date(), quote: quote))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> ()) {
        let sharedDefaults = SharedDefaults.shared
        let currentDate = Date()
        
        // 現在の設定を取得
        let updateFrequency = sharedDefaults.updateFrequency
        
        // エントリーを生成
        var entries: [QuoteEntry] = []
        
        // 現在の名言を取得
        let currentQuote: Quote
        if sharedDefaults.shouldUpdate() {
            // 更新が必要な場合、新しい名言を取得
            currentQuote = sharedDefaults.getQuoteForWidget()
            sharedDefaults.markAsUpdated()
        } else {
            // まだ更新時間でない場合、既存の名言を使用
            currentQuote = sharedDefaults.lastDisplayedQuote ?? sharedDefaults.getQuoteForWidget()
        }
        
        // 現在のエントリー
        entries.append(QuoteEntry(date: currentDate, quote: currentQuote))
        
        // 次の更新時刻を計算
        let nextUpdate = currentDate.addingTimeInterval(updateFrequency.timeInterval)
        
        // 将来のエントリーを生成（次の24時間分）
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        var entryDate = nextUpdate
        
        while entryDate <= endDate {
            let nextQuote = sharedDefaults.getQuoteForWidget()
            entries.append(QuoteEntry(date: entryDate, quote: nextQuote))
            entryDate = entryDate.addingTimeInterval(updateFrequency.timeInterval)
        }
        
        // タイムラインを返す
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    // Note: relevances() is only available in iOS 17.0+, removed for iOS 16.0 compatibility
}

// MARK: - Simple Widget Configuration
// Using basic TimelineProvider for iOS 16.0+ compatibility
// App Intent configuration removed for compatibility