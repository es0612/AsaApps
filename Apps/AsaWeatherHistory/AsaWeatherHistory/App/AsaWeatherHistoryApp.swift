import SwiftUI
import CoreData

@main
struct AsaWeatherHistoryApp: App {
    let coreDataStack = CoreDataStack.shared
    
    init() {
        // アプリ起動時の設定
        setupAppearance()
        
        #if DEBUG
        // デバッグ時にデータベースのパスを出力
        coreDataStack.printDatabasePath()
        #endif
        
        // データベースの最適化（起動時に古いデータを削除）
        coreDataStack.optimizeDatabase()
        
        print("✅ AsaWeatherHistoryアプリが起動しました")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.context)
                .environmentObject(coreDataStack)
                .task {
                    // アプリ起動時に天気データを自動取得
                    await WeatherHistoryService.shared.fetchAndSaveCurrentWeather()
                }
        }
    }
    
    // MARK: - App Appearance Setup
    private func setupAppearance() {
        // ナビゲーションバーの外観設定
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(named: "AsaSoftCream")?.withAlphaComponent(0.9)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(named: "AsaCoffeeBrown") ?? UIColor.brown
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(named: "AsaCoffeeBrown") ?? UIColor.brown
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // タブバーの外観設定
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(named: "AsaSoftCream")?.withAlphaComponent(0.9)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // タブバーアイテムの色設定
        UITabBar.appearance().tintColor = UIColor(named: "AsaCoffeeBrown")
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "AsaMutedSage")
    }
}