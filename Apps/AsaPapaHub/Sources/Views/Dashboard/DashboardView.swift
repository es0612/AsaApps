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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - ドメイングリッド

    private func domainGrid(dataBridge: AppDataBridge) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 12) {
            DomainSummaryCard(
                domain: .health,
                snapshot: dataBridge.snapshot(for: .health),
                subtitle: healthSubtitle(for: dataBridge.todayDashboard)
            ) {
                HealthOverviewView()
            }

            DomainSummaryCard(
                domain: .family,
                snapshot: dataBridge.snapshot(for: .family)
            ) {
                FamilyHubView()
            }

            DomainSummaryCard(
                domain: .finance,
                snapshot: dataBridge.snapshot(for: .finance)
            ) {
                FinanceOverviewView()
            }

            DomainSummaryCard(
                domain: .community,
                snapshot: dataBridge.snapshot(for: .community)
            ) {
                CommunityOverviewView()
            }

            DomainSummaryCard(
                domain: .learning,
                snapshot: dataBridge.snapshot(for: .learning)
            ) {
                LearningOverviewView()
            }

            DomainSummaryCard(
                domain: .morning,
                snapshot: dataBridge.snapshot(for: .morning)
            ) {
                MorningScoreDetailView()
            }
        }
    }

    private func healthSubtitle(for dashboard: HubDashboard?) -> String? {
        guard let dashboard else { return nil }
        return "\(dashboard.stepsCount)歩 ・ \(String(format: "%.1f", dashboard.sleepHours))時間"
    }
}
