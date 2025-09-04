// AsaApps/Apps/AsaMoodChart/AsaMoodChartApp.swift
import SwiftUI

/// AsaMoodChart アプリケーションのエントリポイント
@main
struct AsaMoodChartApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // ブランドガイドラインに合わせてライトモードを推奨
        }
    }
}