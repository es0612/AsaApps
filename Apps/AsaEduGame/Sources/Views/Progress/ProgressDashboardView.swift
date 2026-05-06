import SwiftUI
import AsaEduGameKit
import AsaUIKit

// MARK: - 進捗ダッシュボード

/// 保護者向け進捗ダッシュボード
/// 総合統計、モード別統計、最近のセッション履歴を表示
struct ProgressDashboardView: View {

    // MARK: - Properties

    @Bindable var viewModel: ProgressViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("よみこみちゅう...")
                        .font(.system(size: 16, design: .rounded))
                        .padding(.top, 60)
                } else {
                    VStack(spacing: 24) {
                        // 総合統計
                        overallStatsSection

                        // モード別統計
                        modeStatsSection

                        // グラフセクション
                        chartsSection

                        // 最近のセッション
                        recentSessionsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("しんちょく")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadProgress()
            }
            .refreshable {
                viewModel.loadProgress()
            }
        }
    }

    // MARK: - 総合統計セクション

    private var overallStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("そうごうせいせき")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AsaColors.darkSlate)

            HStack(spacing: 12) {
                statCard(
                    value: "\(totalPlayCount)",
                    label: "プレイかいすう",
                    systemImage: "gamecontroller.fill",
                    color: AsaColors.coffeeBrown
                )

                statCard(
                    value: "\(overallAccuracyPercent)%",
                    label: "せいとうりつ",
                    systemImage: "chart.bar.xaxis",
                    color: AsaColors.mutedSage
                )

                statCard(
                    value: "\(viewModel.profile?.totalStars ?? 0)",
                    label: "かくとくほし",
                    systemImage: "star.fill",
                    color: AsaColors.coffeeBrown
                )
            }
        }
    }

    /// 統計カード
    private func statCard(value: String, label: String, systemImage: String, color: Color) -> some View {
        AsaCard {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(AsaColors.mutedSage)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// 総プレイ回数
    private var totalPlayCount: Int {
        viewModel.modeStats.values.reduce(0) { $0 + $1.totalSessions }
    }

    /// 全体正答率（パーセント）
    private var overallAccuracyPercent: Int {
        let totalCorrect = viewModel.modeStats.values.reduce(0) { $0 + $1.totalCorrect }
        let totalQuestions = viewModel.modeStats.values.reduce(0) { $0 + $1.totalQuestions }
        guard totalQuestions > 0 else { return 0 }
        return Int(Double(totalCorrect) / Double(totalQuestions) * 100)
    }

    // MARK: - モード別統計セクション

    private var modeStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("モードべつせいせき")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AsaColors.darkSlate)

            ForEach(GameMode.allCases, id: \.self) { mode in
                let stats = viewModel.modeStats[mode]
                GameModeStatsView(
                    mode: mode,
                    stats: stats
                )
            }
        }
    }

    // MARK: - グラフセクション

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("グラフ")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AsaColors.darkSlate)

            // 正答率推移グラフ
            AccuracyChartView(sessions: viewModel.recentSessions)

            // モード別星数グラフ
            StarsChartView(modeStats: viewModel.modeStats)
        }
    }

    // MARK: - 最近のセッションセクション

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("さいきんのきろく")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AsaColors.darkSlate)

            if viewModel.recentSessions.isEmpty {
                AsaCard {
                    Text("まだきろくがありません")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            } else {
                ForEach(viewModel.recentSessions.prefix(10), id: \.id) { session in
                    sessionRow(session: session)
                }
            }
        }
    }

    /// セッション行
    private func sessionRow(session: GameSession) -> some View {
        AsaCard {
            HStack(spacing: 12) {
                Image(systemName: session.gameMode.systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(session.gameMode.themeColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(session.gameMode.displayName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AsaColors.darkSlate)

                        Text(session.difficulty.displayName)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(session.gameMode.themeColor)
                            .clipShape(Capsule())
                    }

                    // 日時
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                }

                Spacer()

                // 結果
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.accuracyPercentage)%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(session.isPerfect ? .green : AsaColors.coffeeBrown)

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text("+\(session.earnedStars)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProgressDashboardView(
        viewModel: ProgressViewModel(dataService: EduGameDataService(inMemory: true))
    )
}
