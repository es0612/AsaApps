//
//  ContentView.swift
//  AsaHealthDashboard
//
//  メインTabView
//

import SwiftUI
import SwiftData
import AsaUIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HealthDashboardViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardTab(viewModel: viewModel)
                .tabItem {
                    Label("ダッシュボード", systemImage: "heart.text.square")
                }
                .tag(0)

            ActivityTab(viewModel: viewModel)
                .tabItem {
                    Label("アクティビティ", systemImage: "figure.run")
                }
                .tag(1)

            SleepTab(viewModel: viewModel)
                .tabItem {
                    Label("睡眠", systemImage: "moon.zzz")
                }
                .tag(2)

            TrendTab(viewModel: viewModel)
                .tabItem {
                    Label("トレンド", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)

            SettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(4)
        }
        .tint(AsaColors.coffeeBrown)
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [HealthGoal.self], inMemory: true)
}
