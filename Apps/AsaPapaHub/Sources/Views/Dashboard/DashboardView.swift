import SwiftUI
import SwiftData
import AsaPapaHubKit
import AsaUIKit

// MARK: - ダッシュボードビュー

/// メインダッシュボード - 全ドメインのサマリーを一覧表示
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataBridge: AppDataBridge?
    @State private var isLoading = true

    // MARK: - Body

    var body: some View {
        Group {
            if let dataBridge, !isLoading {
                dashboardContent(dataBridge: dataBridge)
            } else {
                ProgressView("データを読み込み中...")
            }
        }
        .navigationTitle("AsaPapaHub")
        .task {
            let bridge = AppDataBridge(modelContext: modelContext)
            await bridge.loadTodayData()
            dataBridge = bridge
            isLoading = false
        }
        .refreshable {
            await dataBridge?.loadTodayData()
        }
    }

    // MARK: - ダッシュボードコンテンツ

    @ViewBuilder
    private func dashboardContent(dataBridge: AppDataBridge) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // AIブリーフィングエリア
                if let briefing = dataBridge.todayBriefing {
                    briefingCard(briefing)
                }

                // 朝活スコアカード
                MorningScoreCard(
                    score: dataBridge.todayDashboard?.morningScore ?? 0,
                    routine: dataBridge.todayRoutine
                )

                // Siri ティップ
                SiriTipBanner()

                // ドメインサマリーグリッド
                domainGrid(dataBridge: dataBridge)

                // クイックアクションバー
                QuickActionBar(actions: dataBridge.quickActions)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - ブリーフィングカード

    private func briefingCard(_ briefing: DailyBriefing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(AsaColors.coffeeBrown)
                Text("今日のブリーフィング")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(briefing.greeting)
                .font(.body)

            if !briefing.scheduleOverview.isEmpty {
                Text(briefing.scheduleOverview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - ドメイングリッド

    private func domainGrid(dataBridge: AppDataBridge) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 12) {
            HealthSummaryCard(snapshot: dataBridge.snapshot(for: .health), dashboard: dataBridge.todayDashboard)
            FamilySummaryCard(snapshot: dataBridge.snapshot(for: .family))
            FinanceSummaryCard(snapshot: dataBridge.snapshot(for: .finance))
            CommunitySummaryCard(snapshot: dataBridge.snapshot(for: .community))
            LearningSummaryCard(snapshot: dataBridge.snapshot(for: .learning))
            MorningScoreSummaryCard(snapshot: dataBridge.snapshot(for: .morning))
        }
    }
}

// MARK: - 朝活サマリーカード（グリッド用）

private struct MorningScoreSummaryCard: View {
    let snapshot: DomainSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DomainSectionHeader(domain: .morning)

            if let snapshot {
                Text("\(snapshot.score)点")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AsaColors.darkSlate)

                TrendIndicator(trend: snapshot.trend)
            } else {
                Text("--")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}
