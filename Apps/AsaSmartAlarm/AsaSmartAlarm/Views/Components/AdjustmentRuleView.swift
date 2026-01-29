//
//  AdjustmentRuleView.swift
//  AsaSmartAlarm
//
//  調整ルール設定コンポーネント
//

import SwiftUI

// MARK: - 調整ルール設定ビュー

/// 天気による調整ルールを設定するビュー
struct AdjustmentRulesSettingsView: View {
    // MARK: - Properties

    let alarm: SmartAlarm
    let onRuleUpdated: (AlarmAdjustmentRule) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // セクションヘッダー
            Label("天気による調整", systemImage: "cloud.sun.fill")
                .font(.headline)

            // 説明
            Text("悪天候の場合、自動的にアラームを早めます")
                .font(.caption)
                .foregroundStyle(.secondary)

            // ルール一覧
            ForEach(WeatherCondition.allCases.filter { $0.defaultAdjustmentMinutes != 0 }) { condition in
                if let rule = alarm.rule(for: condition) {
                    RuleRow(
                        rule: rule,
                        condition: condition,
                        onUpdate: { onRuleUpdated(rule) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - ルール行

private struct RuleRow: View {
    let rule: AlarmAdjustmentRule
    let condition: WeatherCondition
    let onUpdate: () -> Void

    @State private var isEnabled: Bool
    @State private var adjustmentMinutes: Int

    init(rule: AlarmAdjustmentRule, condition: WeatherCondition, onUpdate: @escaping () -> Void) {
        self.rule = rule
        self.condition = condition
        self.onUpdate = onUpdate
        _isEnabled = State(initialValue: rule.isEnabled)
        _adjustmentMinutes = State(initialValue: rule.adjustmentMinutes)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // 天気アイコンと名前
                HStack(spacing: 8) {
                    Image(systemName: condition.iconName)
                        .foregroundStyle(condition.color)
                        .frame(width: 24)

                    Text(condition.displayName)
                        .fontWeight(.medium)
                }

                Spacer()

                // 有効/無効トグル
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(Color("AsaCoffeeBrown", bundle: nil))
                    .onChange(of: isEnabled) { _, newValue in
                        rule.isEnabled = newValue
                        onUpdate()
                    }
            }

            // 調整時間スライダー（有効時のみ表示）
            if isEnabled {
                HStack {
                    Text("\(adjustmentMinutes)分早く")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .leading)

                    Slider(
                        value: Binding(
                            get: { Double(adjustmentMinutes) },
                            set: { adjustmentMinutes = Int($0) }
                        ),
                        in: 0...60,
                        step: 5
                    )
                    .tint(condition.color)
                    .onChange(of: adjustmentMinutes) { _, newValue in
                        rule.adjustmentMinutes = newValue
                        onUpdate()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - 調整ルールサマリー

/// 適用される調整の要約を表示
struct AdjustmentRuleSummary: View {
    let calculation: AlarmCalculationResult?

    var body: some View {
        if let calc = calculation, calc.hasAdjustments {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(calc.adjustments) { adjustment in
                    AdjustmentItem(adjustment: adjustment)
                }
            }
        } else {
            Text("調整なし")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AdjustmentItem: View {
    let adjustment: AdjustmentDetail

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            Text(adjustment.reason)
                .font(.subheadline)

            Spacer()

            Text(timeText)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(iconColor.opacity(0.1))
                .foregroundStyle(iconColor)
                .clipShape(Capsule())
        }
    }

    private var iconName: String {
        switch adjustment.type {
        case .weather:
            return "cloud.sun.fill"
        case .event:
            return "calendar"
        }
    }

    private var iconColor: Color {
        switch adjustment.type {
        case .weather:
            return .blue
        case .event:
            return .purple
        }
    }

    private var timeText: String {
        if adjustment.minutes > 0 {
            return "-\(adjustment.minutes)分"
        } else {
            return "+\(abs(adjustment.minutes))分"
        }
    }
}

// MARK: - Preview

#Preview("調整ルール設定") {
    let alarm = SmartAlarm.preview

    return ScrollView {
        AdjustmentRulesSettingsView(
            alarm: alarm,
            onRuleUpdated: { _ in }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("調整サマリー") {
    VStack(spacing: 20) {
        GroupBox("調整あり") {
            AdjustmentRuleSummary(calculation: .previewWithAdjustments)
        }

        GroupBox("調整なし") {
            AdjustmentRuleSummary(calculation: .previewNoAdjustments)
        }
    }
    .padding()
}
