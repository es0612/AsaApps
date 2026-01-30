//
//  ContentView.swift
//  AsaFitnessCoach
//
//  メインタブビュー
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FitnessCoachViewModel()
    @State private var selectedTab: Tab = .home

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(Tab.home)

            PlanListView(viewModel: viewModel)
                .tabItem {
                    Label("プラン", systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.plans)

            ProgressDashboardView(viewModel: viewModel)
                .tabItem {
                    Label("進捗", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.progress)

            ProfileView(viewModel: viewModel)
                .tabItem {
                    Label("プロフィール", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(Color("AccentColor"))
        .onAppear {
            viewModel.setModelContext(modelContext)
            Task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Tab

    enum Tab {
        case home
        case plans
        case progress
        case profile
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [
            UserProfile.self,
            WorkoutPlan.self,
            Exercise.self,
            WorkoutSession.self
        ], inMemory: true)
}
