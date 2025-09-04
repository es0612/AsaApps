// AsaApps/Apps/AsaBookTracker/AsaBookTrackerApp.swift
import SwiftUI
import SwiftData
import AsaUIKit

/// AsaBookTrackerアプリのメインエントリポイント
@main
struct AsaBookTrackerApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Book.self, ReadingProgress.self, ReadingSession.self])
                .preferredColorScheme(.light) // ブランドカラーに最適化されたライトモード
        }
        .backgroundTask(.appRefresh("refresh")) { _ in
            // 将来のバックグラウンド更新用
        }
    }
}

// MARK: - App Delegate (if needed for future features)

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // アプリ起動時の初期設定
        setupAppearance()
        
        return true
    }
    
    /// アプリ全体の外観設定
    private func setupAppearance() {
        // ナビゲーションバーの外観
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor(AsaColors.coffeeBrown)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AsaColors.coffeeBrown)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // タブバーの外観
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(AsaColors.coffeeBrown)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AsaColors.coffeeBrown)]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(AsaColors.mutedSage)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(AsaColors.mutedSage)]
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}