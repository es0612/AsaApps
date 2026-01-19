//
//  SettingsTab.swift
//  AsaHealthDashboard
//
//  設定タブ
//

import SwiftUI
import AsaUIKit

struct SettingsTab: View {
    let viewModel: HealthDashboardViewModel
    @State private var showingGoalSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.softCream.opacity(0.1)
                    .ignoresSafeArea()

                List {
                    // 目標設定セクション
                    Section {
                        NavigationLink {
                            GoalSettingView(viewModel: viewModel)
                        } label: {
                            SettingsRow(
                                icon: "target",
                                title: "目標設定",
                                subtitle: "各健康指標の目標値を設定",
                                color: AsaColors.coffeeBrown
                            )
                        }
                    } header: {
                        Text("目標")
                    }

                    // HealthKitセクション
                    Section {
                        HStack {
                            SettingsRow(
                                icon: "heart.text.square",
                                title: "HealthKit連携",
                                subtitle: viewModel.authorizationStatusDescription,
                                color: .red
                            )

                            Spacer()

                            if viewModel.isHealthKitAuthorized {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }

                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            SettingsRow(
                                icon: "gear",
                                title: "権限設定を開く",
                                subtitle: "設定アプリでHealthKitの権限を管理",
                                color: AsaColors.mutedSage
                            )
                        }
                    } header: {
                        Text("HealthKit")
                    }

                    // データセクション
                    Section {
                        Button {
                            Task {
                                await viewModel.refreshAllData()
                            }
                        } label: {
                            SettingsRow(
                                icon: "arrow.clockwise",
                                title: "データを更新",
                                subtitle: "HealthKitから最新データを取得",
                                color: AsaColors.mocha
                            )
                        }
                        .disabled(viewModel.isLoading)
                    } header: {
                        Text("データ")
                    }

                    // アプリ情報セクション
                    Section {
                        SettingsRow(
                            icon: "info.circle",
                            title: "バージョン",
                            subtitle: "1.0.0",
                            color: AsaColors.darkSlate
                        )

                        SettingsRow(
                            icon: "person.crop.circle",
                            title: "開発者",
                            subtitle: "朝活パパエンジニア",
                            color: AsaColors.coffeeBrown
                        )
                    } header: {
                        Text("アプリ情報")
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("設定")
        }
    }
}

// MARK: - 設定行

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AsaColors.darkSlate)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsTab(viewModel: HealthDashboardViewModel())
}
