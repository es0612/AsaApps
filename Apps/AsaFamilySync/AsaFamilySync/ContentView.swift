import SwiftUI
import AsaUIKit

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.currentUser?.familyId != nil {
                    MainTabView()
                } else {
                    FamilySetupView()
                }
            } else {
                AuthenticationView()
            }
        }
        .onAppear {
            authViewModel.checkAuthState()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
                .tag(0)

            EventListView()
                .tabItem {
                    Label("予定", systemImage: "list.bullet")
                }
                .tag(1)

            FamilyDashboardView()
                .tabItem {
                    Label("家族", systemImage: "person.3.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(AsaColors.coffeeBrown)
    }
}

struct FamilySetupView: View {
    @State private var showCreateFamily = false
    @State private var showJoinFamily = false
    @State private var inviteCode = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AsaColors.coffeeBrown)

                VStack(spacing: 8) {
                    Text("家族グループの設定")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("家族グループを作成または参加してください")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 16) {
                    AsaButton(
                        title: "新しい家族グループを作成",
                        action: { showCreateFamily = true },
                        color: AsaColors.coffeeBrown,
                        icon: "plus.circle.fill"
                    )

                    AsaButton(
                        title: "招待コードで参加",
                        action: { showJoinFamily = true },
                        color: AsaColors.mocha,
                        icon: "person.badge.plus.fill"
                    )
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 60)
            .navigationTitle("セットアップ")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showCreateFamily) {
            CreateFamilyView()
        }
        .sheet(isPresented: $showJoinFamily) {
            JoinFamilyView()
        }
    }
}