import AsaSmartReminderKit
import AsaUIKit
import SwiftUI

// MARK: - メインコンテンツビュー

struct ContentView: View {
    let dataService: ReminderDataService
    @State private var viewModel: SmartReminderViewModel
    @State private var settingsViewModel: SettingsViewModel
    @State private var permissionService = PermissionService()
    @State private var showOnboarding = false

    init(dataService: ReminderDataService) {
        self.dataService = dataService
        let vm = SmartReminderViewModel(dataService: dataService)
        _viewModel = State(initialValue: vm)
        _settingsViewModel = State(initialValue: SettingsViewModel(dataService: dataService))
    }

    var body: some View {
        TabView {
            ReminderListView(viewModel: viewModel, dataService: dataService)
                .tabItem {
                    Label("リマインダー", systemImage: "bell.fill")
                }

            MapOverviewView(viewModel: viewModel)
                .tabItem {
                    Label("地図", systemImage: "map.fill")
                }

            LocationManagementView(viewModel: viewModel, dataService: dataService)
                .tabItem {
                    Label("場所", systemImage: "mappin.circle.fill")
                }

            SettingsView(
                viewModel: settingsViewModel,
                permissionService: permissionService,
                monitoringState: viewModel.monitoringState
            )
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
        }
        .tint(AsaColors.coffeeBrown)
        .task {
            await permissionService.checkCurrentStatus()
            if permissionService.permissionStatus.needsOnboarding {
                showOnboarding = true
            }
            viewModel.loadData()
            settingsViewModel.loadSettings()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            PermissionOnboardingView(permissionService: permissionService) {
                showOnboarding = false
            }
        }
    }
}
