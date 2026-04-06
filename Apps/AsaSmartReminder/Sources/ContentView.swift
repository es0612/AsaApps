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
            // 初回起動時にデモ用サンプルデータを投入（オンボーディングはスキップ）
            loadSampleDataIfNeeded()

            // サンプルデータ未投入かつ権限未設定ならオンボーディング表示
            if permissionService.permissionStatus.needsOnboarding && !isSampleDataLoaded {
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

    // MARK: - Sample Data Loading

    private var sampleDataKey: String { "AsaSmartReminder_SampleDataLoaded_v1" }

    private var isSampleDataLoaded: Bool {
        UserDefaults.standard.bool(forKey: sampleDataKey)
    }

    /// 初回起動時にデモ用サンプルデータを投入
    /// - 5つの場所と10件のリマインダーを自動生成
    /// - オンボーディングはスキップ（位置情報権限ダイアログを回避）
    private func loadSampleDataIfNeeded() {
        guard !isSampleDataLoaded else { return }

        let sampleService = SampleDataService(dataService: dataService)
        do {
            try sampleService.loadSampleData()
            UserDefaults.standard.set(true, forKey: sampleDataKey)
        } catch {
            print("サンプルデータ投入エラー: \(error.localizedDescription)")
        }
    }
}
