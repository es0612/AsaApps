//
//  DashboardTab.swift
//  AsaHealthDashboard
//
//  ダッシュボードタブ
//

import SwiftUI
import AsaUIKit

struct DashboardTab: View {
    let viewModel: HealthDashboardViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.softCream.opacity(0.1)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.todayMetrics.isEmpty {
                    LoadingView()
                } else if !viewModel.isHealthKitAuthorized {
                    HealthKitPermissionView(viewModel: viewModel)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 今日のサマリー
                            TodaySummaryCard(metrics: viewModel.todayMetrics)

                            // 目標達成グリッド
                            GoalProgressGrid(metrics: viewModel.todayMetrics)

                            // 週間ハイライト
                            if let highlights = viewModel.weeklyHighlights {
                                WeeklyHighlightCard(highlights: highlights)
                            }

                            // 健康スコア
                            if let score = viewModel.healthScore {
                                HealthScoreCard(score: score)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refreshAllData()
                    }
                }
            }
            .navigationTitle("ヘルスダッシュボード")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refreshAllData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
}

// MARK: - 健康スコアカード

struct HealthScoreCard: View {
    let score: HealthScore

    var body: some View {
        AsaCard {
            VStack(spacing: 16) {
                HStack {
                    Text("今日の健康スコア")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    Text(score.grade)
                        .font(.title.bold())
                        .foregroundColor(score.color)
                }

                ZStack {
                    Circle()
                        .stroke(AsaColors.softCream, lineWidth: 12)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: CGFloat(score.score) / 100)
                        .stroke(score.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: score.score)

                    Text("\(score.score)")
                        .font(.title.bold())
                        .foregroundColor(AsaColors.darkSlate)
                }

                Text(score.message)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        DashboardTab(viewModel: HealthDashboardViewModel())
    }
}
