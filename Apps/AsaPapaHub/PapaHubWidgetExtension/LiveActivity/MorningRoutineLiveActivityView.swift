//
//  MorningRoutineLiveActivityView.swift
//  PapaHubWidgetExtension
//
//  朝活ルーティン Live Activity の UI
//  Lock Screen / Dynamic Island での表示
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - MorningRoutineLiveActivity

/// 朝活ルーティン Live Activity ウィジェット
struct MorningRoutineLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MorningRoutineAttributes.self) { context in
            // Lock Screen プレゼンテーション
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
            } compactLeading: {
                // Compact Leading: アイテムアイコン
                Image(systemName: context.state.currentItemIcon)
                    .foregroundStyle(coffeeBrown)
                    .font(.caption)
            } compactTrailing: {
                // Compact Trailing: "2/5" 形式
                Text("\(context.state.completedCount)/\(context.state.totalCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(coffeeBrown)
            } minimal: {
                // Minimal: スコア数字
                Text("\(context.state.currentScore)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(coffeeBrown)
            }
        }
    }

    // MARK: - Colors

    private let coffeeBrown = Color(red: 0.776, green: 0.549, blue: 0.325)
    private let darkSlate = Color(red: 0.184, green: 0.243, blue: 0.275)
    private let softCream = Color(red: 0.910, green: 0.835, blue: 0.725)

    // MARK: - Lock Screen

    private func lockScreenView(context: ActivityViewContext<MorningRoutineAttributes>) -> some View {
        HStack(spacing: 16) {
            // 左: スコアリング
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(softCream, lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: CGFloat(context.state.currentScore) / 100.0)
                        .stroke(coffeeBrown, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    Text("\(context.state.currentScore)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(darkSlate)
                }

                Text("スコア")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // 中: 現在のアイテム + プログレス
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: context.state.currentItemIcon)
                        .font(.caption)
                        .foregroundStyle(coffeeBrown)

                    Text(context.state.currentItemName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(darkSlate)
                }

                // プログレスバー
                progressBar(
                    completed: context.state.completedCount,
                    total: context.state.totalCount
                )

                HStack {
                    Text("\(context.state.completedCount)/\(context.state.totalCount) 完了")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(context.state.elapsedMinutes)分経過")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
    }

    // MARK: - Dynamic Island Expanded

    private func expandedLeading(context: ActivityViewContext<MorningRoutineAttributes>) -> some View {
        HStack(spacing: 6) {
            Image(systemName: context.state.currentItemIcon)
                .foregroundStyle(coffeeBrown)

            Text(context.state.currentItemName)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    private func expandedTrailing(context: ActivityViewContext<MorningRoutineAttributes>) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(context.state.currentScore)点")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(coffeeBrown)

            Text("\(context.state.elapsedMinutes)分")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func expandedBottom(context: ActivityViewContext<MorningRoutineAttributes>) -> some View {
        VStack(spacing: 4) {
            progressBar(
                completed: context.state.completedCount,
                total: context.state.totalCount
            )

            HStack {
                Text("\(context.state.completedCount)/\(context.state.totalCount) 完了")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("目標: \(context.attributes.targetDurationMinutes)分")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func progressBar(completed: Int, total: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(softCream)
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(coffeeBrown)
                    .frame(
                        width: total > 0
                            ? geo.size.width * CGFloat(completed) / CGFloat(total)
                            : 0,
                        height: 6
                    )
            }
        }
        .frame(height: 6)
    }
}
