import SwiftUI
import WidgetKit

@main
struct AsaQuoteWidgetApp: App {
    
    init() {
        // アプリ起動時にウィジェットを更新
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 初期設定の確認
                    checkInitialSetup()
                }
        }
    }
    
    private func checkInitialSetup() {
        let sharedDefaults = SharedDefaults.shared
        
        // 初回起動時の設定
        if sharedDefaults.lastUpdateTime == nil {
            sharedDefaults.resetToDefaults()
            sharedDefaults.markAsUpdated()
            
            // 初期名言を設定
            let initialQuote = QuoteDataProvider.shared.getRandomQuote()
            sharedDefaults.lastDisplayedQuote = initialQuote
            
            print("初期設定を完了しました")
        }
    }
}