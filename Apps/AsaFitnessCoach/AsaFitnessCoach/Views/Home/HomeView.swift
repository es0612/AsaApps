//
//  HomeView.swift
//  AsaFitnessCoach
//
//  ホーム画面
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties

    @Bindable var viewModel: FitnessCoachViewModel
    @State private var showOnboarding = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日のサマリー
                    todaySummarySection

                    // 今日のワークアウト
                    if !viewModel.todayPlans.isEmpty {
                        todayWorkoutSection
                    }

                    // AI提案
                    if let recommendation = viewModel.aiRecommendation {
                        aiRecommendationSection(recommendation)
                    }

                    // プログレッシブオーバーロード提案
                    if !viewModel.overloadSuggestions.isEmpty {
                        overloadSuggestionsSection
                    }

                    // 週間統計
                    if let stats = viewModel.weeklyStats {
                        weeklyStatsSection(stats)
                    }
                }
                .padding()
            }
            .navigationTitle("AsaFitnessCoach")
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(viewModel: viewModel)
            }
            .onAppear {
                if viewModel.showOnboarding {
                    showOnboarding = true
                }
            }
        }
    }

    // MARK: - Today Summary

    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の活動")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SummaryCard(
                    title: "歩数",
                    value: "\(Int(viewModel.todaySteps))",
                    icon: "figure.walk",
                    color: .blue
                )

                SummaryCard(
                    title: "カロリー",
                    value: "\(Int(viewModel.todayCalories)) kcal",
                    icon: "flame.fill",
                    color: .orange
                )

                SummaryCard(
                    title: "運動時間",
                    value: "\(Int(viewModel.todayActiveTime)) 分",
                    icon: "timer",
                    color: .green
                )

                SummaryCard(
                    title: "ワークアウト",
                    value: "\(viewModel.todayWorkoutCount) 回",
                    icon: "dumbbell.fill",
                    color: .purple
                )
            }

            // HealthKit未連携の場合
            if !viewModel.healthKitService_.isAuthorized {
                Button {
                    Task {
                        await viewModel.requestHealthKitAuthorization()
                    }
                } label: {
                    Label("HealthKitと連携", systemImage: "heart.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Today Workout

    private var todayWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日のワークアウト")
                .font(.headline)

            ForEach(viewModel.todayPlans) { plan in
                TodayWorkoutCard(
                    plan: plan,
                    onStart: {
                        // ワークアウト開始処理
                    }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - AI Recommendation

    private func aiRecommendationSection(_ recommendation: AIRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("AI提案")
                    .font(.headline)

                Spacer()

                Button {
                    viewModel.regenerateRecommendation()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                }
            }

            AIRecommendationCard(
                recommendation: recommendation,
                onAccept: {
                    viewModel.createPlanFromRecommendation(recommendation)
                }
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Overload Suggestions

    private var overloadSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.green)
                Text("負荷増加の提案")
                    .font(.headline)
            }

            ForEach(viewModel.overloadSuggestions.prefix(3)) { suggestion in
                OverloadSuggestionRow(suggestion: suggestion)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Weekly Stats

    private func weeklyStatsSection(_ stats: WeeklyStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今週の実績")
                .font(.headline)

            HStack(spacing: 20) {
                StatItem(
                    title: "ワークアウト",
                    value: "\(stats.workoutCount) 回"
                )

                StatItem(
                    title: "合計時間",
                    value: stats.displayDuration
                )

                StatItem(
                    title: "消費カロリー",
                    value: "\(Int(stats.totalCalories)) kcal"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct OverloadSuggestionRow: View {
    let suggestion: ProgressiveOverloadSuggestion

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(suggestion.displayWeightChange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(suggestion.displayIncrease)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    HomeView(viewModel: FitnessCoachViewModel())
}
