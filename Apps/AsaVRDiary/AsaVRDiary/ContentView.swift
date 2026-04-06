//
//  ContentView.swift
//  AsaVRDiary
//
//  メインコンテンツビュー
//

import SwiftUI

/// メインコンテンツビュー
struct ContentView: View {
    @State private var diaryViewModel: DiaryViewModel
    @State private var vrViewModel: VRSceneViewModel
    @State private var statsViewModel: StatsViewModel
    @State private var selectedTab: Tab = .diary

    private enum Tab: String, CaseIterable {
        case diary = "diary"
        case vr = "vr"
        case stats = "stats"

        var title: String {
            switch self {
            case .diary: return "日記"
            case .vr: return "VR空間"
            case .stats: return "統計"
            }
        }

        var icon: String {
            switch self {
            case .diary: return "book.fill"
            case .vr: return "cube.transparent"
            case .stats: return "chart.bar.fill"
            }
        }
    }

    init(dataService: DiaryDataService? = nil) {
        let service = dataService ?? DiaryDataService()

        // 初回起動時にデモ用サンプルデータを自動投入
        let sampleDataKey = "AsaVRDiary_SampleDataLoaded_v1"
        if !UserDefaults.standard.bool(forKey: sampleDataKey) {
            service.createSampleData()
            UserDefaults.standard.set(true, forKey: sampleDataKey)
        }

        _diaryViewModel = State(initialValue: DiaryViewModel(dataService: service))
        _vrViewModel = State(initialValue: VRSceneViewModel())
        _statsViewModel = State(initialValue: StatsViewModel(dataService: service))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 日記タブ
            DiaryListView(viewModel: diaryViewModel)
                .tabItem {
                    Label(Tab.diary.title, systemImage: Tab.diary.icon)
                }
                .tag(Tab.diary)

            // VR空間タブ
            VRDiaryView(
                diaryViewModel: diaryViewModel,
                vrViewModel: vrViewModel
            )
            .tabItem {
                Label(Tab.vr.title, systemImage: Tab.vr.icon)
            }
            .tag(Tab.vr)

            // 統計タブ
            StatsView(viewModel: statsViewModel)
                .tabItem {
                    Label(Tab.stats.title, systemImage: Tab.stats.icon)
                }
                .tag(Tab.stats)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .stats {
                statsViewModel.loadStats()
            }
        }
    }
}

#Preview {
    ContentView()
}
