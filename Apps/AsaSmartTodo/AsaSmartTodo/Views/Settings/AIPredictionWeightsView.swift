//
//  AIPredictionWeightsView.swift
//  AsaSmartTodo
//
//  AI予測の重み設定画面
//  6要因の重み付けを調整し、合計100%を検証
//

import SwiftUI
import AsaUIKit

struct AIPredictionWeightsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showResetAlert = false

    var body: some View {
        List {
            Section {
                Text("AI予測に使用する6要因の重み付けを調整できます。合計が100%になるように自動調整されます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("要因の重み付け") {
                WeightSlider(
                    title: "期限",
                    subtitle: "タスクの締切までの日数",
                    weight: $viewModel.settings.dueDateWeight,
                    icon: "calendar.badge.clock",
                    color: .red
                )

                WeightSlider(
                    title: "カテゴリ",
                    subtitle: "タスクのカテゴリ重要度",
                    weight: $viewModel.settings.categoryWeight,
                    icon: "folder.fill",
                    color: AsaColors.coffeeBrown
                )

                WeightSlider(
                    title: "タイトル複雑度",
                    subtitle: "タイトルの詳細さ",
                    weight: $viewModel.settings.titleComplexityWeight,
                    icon: "text.alignleft",
                    color: AsaColors.mocha
                )

                WeightSlider(
                    title: "説明詳細度",
                    subtitle: "説明文の充実度",
                    weight: $viewModel.settings.descriptionWeight,
                    icon: "doc.text.fill",
                    color: AsaColors.mutedSage
                )

                WeightSlider(
                    title: "朝活時間帯",
                    subtitle: "5:00-7:00の作成ボーナス",
                    weight: $viewModel.settings.timeOfDayWeight,
                    icon: "sunrise.fill",
                    color: .orange
                )

                WeightSlider(
                    title: "履歴完了率",
                    subtitle: "過去の完了実績（将来実装）",
                    weight: $viewModel.settings.historicalWeight,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }

            Section {
                HStack {
                    Text("合計")
                        .font(.headline)

                    Spacer()

                    Text("\(Int(viewModel.settings.totalWeights * 100))%")
                        .font(.headline)
                        .foregroundColor(
                            viewModel.settings.isWeightsValid
                                ? AsaColors.coffeeBrown
                                : .red
                        )
                }

                if !viewModel.settings.isWeightsValid {
                    Text("重みの合計が100%ではありません。保存時に自動調整されます。")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("デフォルトに戻す")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("AI予測の重み設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    viewModel.updateAIWeights()
                    viewModel.saveSettings()
                }
                .foregroundColor(AsaColors.coffeeBrown)
            }
        }
        .alert("デフォルトに戻す", isPresented: $showResetAlert) {
            Button("リセット", role: .destructive) {
                viewModel.resetAIWeights()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("すべての重み設定をデフォルト値に戻します。")
        }
    }
}

// MARK: - Weight Slider Component

struct WeightSlider: View {
    let title: String
    let subtitle: String
    @Binding var weight: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(weight * 100))%")
                    .font(.headline)
                    .foregroundColor(color)
                    .frame(width: 50, alignment: .trailing)
            }

            Slider(value: $weight, in: 0...1, step: 0.05)
                .tint(color)
        }
        .padding(.vertical, 4)
    }
}
