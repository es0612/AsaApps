//
//  ContentView.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import AsaUIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var budgetViewModel = BudgetViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("ダッシュボード", systemImage: "chart.pie.fill")
                }
                .tag(0)

            TransactionListView()
                .tabItem {
                    Label("取引", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            BudgetPlanView()
                .tabItem {
                    Label("予算計画", systemImage: "calendar")
                }
                .tag(2)

            FamilyMembersView()
                .tabItem {
                    Label("家族", systemImage: "person.3.fill")
                }
                .tag(3)
        }
        .environmentObject(budgetViewModel)
        .tint(AsaColors.coffeeBrown)
    }
}