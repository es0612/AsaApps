//
//  ContentView.swift
//  AsaWorkoutPlanner
//
//  メインビュー - タブナビゲーション
//

import SwiftUI
import SwiftData
import AsaUIKit

struct ContentView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WorkoutPlannerViewModel()
    @State private var selectedTab = 0
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム画面
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)
            
            // プラン一覧
            PlanListView(viewModel: viewModel)
                .tabItem {
                    Label("プラン", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            
            // ワークアウト開始
            WorkoutStartView(viewModel: viewModel)
                .tabItem {
                    Label("開始", systemImage: "play.circle.fill")
                }
                .tag(2)
            
            // 進捗
            WorkoutProgressView(viewModel: viewModel)
                .tabItem {
                    Label("進捗", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
            
            // 設定
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color(AsaColors.coffeeBrown))
        .onAppear {
            setupViewModel()
        }
    }
    
    // MARK: - Methods
    
    private func setupViewModel() {
        viewModel = WorkoutPlannerViewModel(modelContext: modelContext)
    }
}