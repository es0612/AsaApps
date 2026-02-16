import SwiftUI
import SwiftData
import AsaPapaHubKit
import AsaUIKit

// MARK: - 朝活ルーティンビュー

/// 朝活ルーティンの管理・実行ビュー
struct MorningRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataBridge: AppDataBridge?
    @State private var elapsedSeconds: Int = 0
    @State private var isRunning = false
    nonisolated(unsafe) private var timer: Timer?

    // MARK: - Body

    var body: some View {
        Group {
            if let dataBridge, let routine = dataBridge.todayRoutine {
                routineContent(routine: routine, dataBridge: dataBridge)
            } else {
                EmptyDomainView(
                    domain: .morning,
                    message: "今日のルーティンがまだ設定されていません"
                )
            }
        }
        .navigationTitle("朝活ルーティン")
        .task {
            let bridge = AppDataBridge(modelContext: modelContext)
            await bridge.loadTodayData()
            dataBridge = bridge
        }
    }

    // MARK: - ルーティンコンテンツ

    @ViewBuilder
    private func routineContent(routine: MorningRoutine, dataBridge: AppDataBridge) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // スコア表示
                scoreSection(routine: routine)

                // タイマーセクション
                timerSection(routine: routine, dataBridge: dataBridge)

                // ルーティンアイテムリスト
                itemsList(routine: routine, dataBridge: dataBridge)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - スコアセクション

    private func scoreSection(routine: MorningRoutine) -> some View {
        VStack(spacing: 12) {
            ScoreRing(
                progress: routine.completionRate,
                lineWidth: 14,
                size: 140,
                gradientColors: [.orange, AsaColors.coffeeBrown],
                label: "完了"
            )

            Text("\(routine.completedItemsCount) / \(routine.items.count) 完了")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: - タイマーセクション

    private func timerSection(routine: MorningRoutine, dataBridge: AppDataBridge) -> some View {
        VStack(spacing: 12) {
            if routine.isCompleted {
                Label("ルーティン完了！", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)

                if let duration = routine.actualDurationMinutes {
                    Text("所要時間: \(duration)分")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if routine.startTime != nil {
                // 実行中
                Text(formattedTime(elapsedSeconds))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundStyle(AsaColors.coffeeBrown)

                Button {
                    dataBridge.finishRoutine()
                    isRunning = false
                } label: {
                    Label("ルーティンを終了", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AsaColors.mocha, in: RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // まだ開始していない
                Button {
                    dataBridge.startRoutine()
                    isRunning = true
                } label: {
                    Label("朝活を始める", systemImage: "sunrise.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AsaColors.coffeeBrown, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: - アイテムリスト

    private func itemsList(routine: MorningRoutine, dataBridge: AppDataBridge) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ルーティンアイテム")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(routine.items.sorted(by: { $0.order < $1.order }), id: \.id) { item in
                RoutineItemRow(
                    item: item,
                    onComplete: { dataBridge.completeRoutineItem(item) },
                    onSkip: { dataBridge.skipRoutineItem(item) }
                )
            }
        }
    }

    // MARK: - ヘルパー

    private func formattedTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
