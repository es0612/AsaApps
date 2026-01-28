import SwiftUI

/// AI最適化結果を表示するカード
struct OptimizationCardView: View {
    let result: OptimizationResult
    let topItems: [StudyItem]
    let onItemTap: (StudyItem) -> Void
    let onAccept: (StudyItem) -> Void
    let onReject: (StudyItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("AI最適化")
                    .font(.headline)
                Spacer()

                // 信頼度バッジ
                ConfidenceBadge(score: result.confidenceScore)
            }

            // 最適化理由
            if !result.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(result.reasons.prefix(3), id: \.self) { reason in
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // 推奨学習項目
            Text("推奨学習順序")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(topItems.enumerated()), id: \.element.id) { index, item in
                OptimizationItemRow(
                    rank: index + 1,
                    item: item,
                    score: result.priorityScores[item.id] ?? 0,
                    onTap: { onItemTap(item) },
                    onAccept: { onAccept(item) },
                    onReject: { onReject(item) }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let score: Double

    private var percentage: Int {
        Int(score * 100)
    }

    private var color: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .gray
        }
    }

    var body: some View {
        Text("信頼度 \(percentage)%")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Optimization Item Row

struct OptimizationItemRow: View {
    let rank: Int
    let item: StudyItem
    let score: Double
    let onTap: () -> Void
    let onAccept: () -> Void
    let onReject: () -> Void

    @State private var showActions = false

    var body: some View {
        Button(action: { showActions.toggle() }) {
            HStack(spacing: 12) {
                // ランク
                Text("\(rank)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(rankColor)
                    .clipShape(Circle())

                // 項目情報
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.category.emoji)
                        Text(item.title)
                            .font(.subheadline)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Text(item.difficulty.displayName)
                            .font(.caption2)
                            .foregroundStyle(item.difficulty.color)

                        if let days = item.daysUntilTarget {
                            Text(days < 0 ? "期限切れ" : "あと\(days)日")
                                .font(.caption2)
                                .foregroundStyle(days < 0 ? .red : .secondary)
                        }

                        if item.needsReview {
                            Label("復習", systemImage: "arrow.clockwise")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Spacer()

                // スコア
                VStack(alignment: .trailing) {
                    Text(String(format: "%.0f", score * 100))
                        .font(.headline)
                        .foregroundStyle(.purple)
                    Text("pt")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if showActions {
            HStack(spacing: 12) {
                Button {
                    onAccept()
                    showActions = false
                } label: {
                    Label("この順序で学習", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    onReject()
                    showActions = false
                } label: {
                    Label("スキップ", systemImage: "xmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            .padding(.leading, 40)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .purple
        case 2: return Color("AsaCoffeeBrown")
        case 3: return .orange
        default: return .gray
        }
    }
}

// MARK: - AI Insights View

struct AIInsightsView: View {
    let result: OptimizationResult
    let reviewStats: ReviewStatistics?
    let morningScore: Int
    let urgentCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("AIインサイト")
                    .font(.headline)
            }

            // インサイトカード
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InsightCard(
                    icon: "sparkles",
                    title: "最適化スコア",
                    value: String(format: "%.0f%%", result.overallScore * 100),
                    color: .purple
                )

                if let stats = reviewStats {
                    InsightCard(
                        icon: "arrow.clockwise",
                        title: "復習健全性",
                        value: String(format: "%.0f%%", stats.healthScore * 100),
                        color: stats.healthScore > 0.7 ? .green : .orange
                    )
                }

                InsightCard(
                    icon: "sunrise.fill",
                    title: "朝活スコア",
                    value: "\(morningScore)",
                    color: morningScore > 60 ? .yellow : .orange
                )

                InsightCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "緊急項目",
                    value: "\(urgentCount)件",
                    color: urgentCount > 0 ? .red : .green
                )
            }

            // 推奨アクション
            if !result.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("推奨アクション")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(result.reasons, id: \.self) { reason in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(reason)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 20) {
        OptimizationCardView(
            result: OptimizationResult(
                orderedItemIds: [],
                priorityScores: [:],
                reasons: ["🎯 「Swift並行処理」を最優先で学習することを推奨します", "🔄 2件の復習が必要な項目があります"],
                overallScore: 0.75,
                confidenceScore: 0.85,
                weightsUsed: .default
            ),
            topItems: [
                StudyItem(title: "Swift並行処理", category: .programming, difficulty: .hard),
                StudyItem(title: "英語リーディング", category: .language, difficulty: .medium)
            ],
            onItemTap: { _ in },
            onAccept: { _ in },
            onReject: { _ in }
        )

        AIInsightsView(
            result: .empty,
            reviewStats: ReviewStatistics(itemsNeedingReviewToday: 2, totalItemsWithSchedule: 10, averageEaseFactor: 2.5),
            morningScore: 75,
            urgentCount: 1
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
