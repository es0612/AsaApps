//
//  ContentView.swift
//  AsaSmartAlarm
//
//  メインコンテンツビュー
//

import SwiftUI
import SwiftData
import AsaUIKit

// MARK: - コンテンツビュー

/// アプリのメインコンテンツを表示するビュー
struct ContentView: View {
    // MARK: - Properties

    @State private var alarmViewModel = AlarmViewModel()
    @State private var eventViewModel = EventViewModel()
    @State private var weatherViewModel: WeatherViewModel
    @State private var locationService = LocationService()

    @State private var selectedTab: Tab = .alarms
    @State private var dataService: DataService?

    // MARK: - Initializer

    init() {
        let locationService = LocationService()
        _locationService = State(initialValue: locationService)
        _weatherViewModel = State(initialValue: WeatherViewModel(locationService: locationService))
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // アラーム
            AlarmListView(
                viewModel: alarmViewModel,
                weatherViewModel: weatherViewModel
            )
            .tabItem {
                Label("アラーム", systemImage: "alarm.fill")
            }
            .tag(Tab.alarms)

            // 予定
            EventListView(viewModel: eventViewModel)
                .tabItem {
                    Label("予定", systemImage: "calendar")
                }
                .tag(Tab.events)
        }
        .tint(AsaColors.coffeeBrown)
        .task {
            await setupApp()
        }
        .onChange(of: eventViewModel.tomorrowMorningEvents) { _, newEvents in
            // イベントが更新されたらアラームViewModelに通知
            Task {
                await alarmViewModel.eventsUpdated(newEvents)
            }
        }
        .onChange(of: weatherViewModel.morningForecast) { _, newForecast in
            // 天気が更新されたらアラームViewModelに通知
            Task {
                await alarmViewModel.weatherForecastUpdated(newForecast)
            }
        }
    }

    // MARK: - Private Methods

    private func setupApp() async {
        do {
            // DataServiceを初期化
            let service = try DataService()
            dataService = service

            // ViewModelにDataServiceを設定
            alarmViewModel.setup(dataService: service)
            eventViewModel.setup(dataService: service)

            // 位置情報の権限をリクエスト
            locationService.requestAuthorization()

            // 天気を取得
            await weatherViewModel.refreshWeather()

            print("🚀 アプリのセットアップ完了")
        } catch {
            print("🚀 セットアップエラー: \(error)")
        }
    }
}

// MARK: - タブ

private enum Tab {
    case alarms
    case events
}

// MARK: - Preview

#Preview("メイン画面") {
    ContentView()
}
