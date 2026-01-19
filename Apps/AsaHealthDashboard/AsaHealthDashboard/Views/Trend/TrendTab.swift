//
//  TrendTab.swift
//  AsaHealthDashboard
//
//  トレンドタブ
//

import SwiftUI
import AsaUIKit

struct TrendTab: View {
    let viewModel: HealthDashboardViewModel
    @State private var selectedPeriod: TimePeriod = .week

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.softCream.opacity(0.1)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 期間セレクター
                        SegmentedPeriodSelector(selectedPeriod: $selectedPeriod)
                            .padding(.horizontal)

                        // 総合健康スコア
                        if let score = viewModel.healthScore {
                            HealthScoreView(score: score)
                        }

                        // 各カテゴリのトレンド
                        VStack(alignment: .leading, spacing: 12) {
                            Text("カテゴリ別トレンド")
                                .font(.headline)
                                .foregroundColor(AsaColors.darkSlate)
                                .padding(.horizontal)

                            ForEach(HealthCategory.allCases) { category in
                                if let analysis = viewModel.trend(for: category) {
                                    TrendAnalysisCard(analysis: analysis)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("トレンド")
            .onChange(of: selectedPeriod) { _, newPeriod in
                Task {
                    await viewModel.changePeriod(to: newPeriod)
                    await viewModel.loadTrendAnalysis()
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadTrendAnalysis()
                }
            }
        }
    }
}

// MARK: - 健康スコアビュー

struct HealthScoreView: View {
    let score: HealthScore

    var body: some View {
        AsaCard {
            VStack(spacing: 20) {
                Text("総合健康スコア")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                // スコアリング
                ZStack {
                    Circle()
                        .stroke(AsaColors.softCream, lineWidth: 16)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: CGFloat(score.score) / 100)
                        .stroke(
                            score.color,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: score.score)

                    VStack(spacing: 4) {
                        Text("\(score.score)")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(AsaColors.darkSlate)

                        Text(score.grade)
                            .font(.title2.bold())
                            .foregroundColor(score.color)
                    }
                }

                Text(score.message)
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)
                    .multilineTextAlignment(.center)

                Divider()

                // カテゴリ別スコア
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(HealthCategory.allCases) { category in
                        let categoryScore = score.breakdown[category] ?? 0
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(category.color.opacity(0.2), lineWidth: 4)
                                    .frame(width: 44, height: 44)

                                Circle()
                                    .trim(from: 0, to: CGFloat(categoryScore) / 100)
                                    .stroke(category.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 44, height: 44)
                                    .rotationEffect(.degrees(-90))

                                Image(systemName: category.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(category.color)
                            }

                            Text("\(categoryScore)%")
                                .font(.system(size: 10))
                                .foregroundColor(AsaColors.mutedSage)
                        }
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

// MARK: - トレンド分析カード

struct TrendAnalysisCard: View {
    let analysis: TrendAnalysis

    var body: some View {
        AsaCard {
            HStack(spacing: 16) {
                // カテゴリアイコン
                Image(systemName: analysis.category.icon)
                    .font(.title2)
                    .foregroundColor(analysis.category.color)
                    .frame(width: 44, height: 44)
                    .background(analysis.category.color.opacity(0.1))
                    .cornerRadius(10)

                // カテゴリ情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(analysis.formattedCurrentAverage)
                            .font(.title3.bold())
                            .foregroundColor(AsaColors.darkSlate)

                        Text(analysis.category.unit)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)

                        Text("/ 日平均")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                Spacer()

                // トレンド表示
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: analysis.trend.icon)
                            .font(.caption)

                        Text(analysis.formattedChange)
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(analysis.adjustedTrendColor)

                    Text("前期間比")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

#Preview {
    TrendTab(viewModel: HealthDashboardViewModel())
}
