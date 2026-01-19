//
//  AsaHealthDashboardApp.swift
//  AsaHealthDashboard
//
//  健康データを統合表示するダッシュボードアプリ
//  Created on 2026/01/19
//

import SwiftUI
import SwiftData

@main
struct AsaHealthDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [HealthGoal.self])
    }
}
