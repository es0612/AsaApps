//
//  AlarmRowView.swift
//  AsaSmartAlarm
//
//  アラーム行コンポーネント
//

import SwiftUI

// MARK: - アラーム行ビュー

/// アラーム一覧で使用する行ビュー
struct AlarmRowView: View {
    // MARK: - Properties

    let alarm: SmartAlarm
    let calculation: AlarmCalculationResult?
    let onToggle: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            // 時刻表示
            VStack(alignment: .leading, spacing: 4) {
                // メイン時刻（調整後）
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(displayTime)
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundStyle(alarm.isEnabled ? .primary : .secondary)

                    // 調整インジケーター
                    if let calc = calculation, calc.hasAdjustments {
                        AdjustmentBadge(minutes: calc.totalAdjustmentMinutes)
                    }
                }

                // ラベルと繰り返し
                HStack(spacing: 8) {
                    if !alarm.label.isEmpty {
                        Text(alarm.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(alarm.repeatDaysDescription)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // スマート機能インジケーター
                if alarm.weatherAdjustmentEnabled || alarm.eventAdjustmentEnabled {
                    SmartFeaturesIndicator(
                        weatherEnabled: alarm.weatherAdjustmentEnabled,
                        eventEnabled: alarm.eventAdjustmentEnabled
                    )
                }
            }

            Spacer()

            // トグルスイッチ
            Toggle("", isOn: .constant(alarm.isEnabled))
                .labelsHidden()
                .tint(Color("AsaCoffeeBrown", bundle: nil))
                .onChange(of: alarm.isEnabled) { _, _ in }
                .onTapGesture {
                    onToggle()
                }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Computed Properties

    /// 表示する時刻（調整後があれば調整後を表示）
    private var displayTime: String {
        if let calc = calculation {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: calc.adjustedTime)
        }
        return alarm.timeString
    }
}

// MARK: - 調整バッジ

/// 調整時間を表示するバッジ
private struct AdjustmentBadge: View {
    let minutes: Int

    var body: some View {
        Text(adjustmentText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var adjustmentText: String {
        if minutes > 0 {
            return "-\(minutes)分"
        } else {
            return "+\(abs(minutes))分"
        }
    }

    private var badgeColor: Color {
        minutes > 0 ? .orange : .blue
    }
}

// MARK: - スマート機能インジケーター

/// 有効なスマート機能を表示するインジケーター
private struct SmartFeaturesIndicator: View {
    let weatherEnabled: Bool
    let eventEnabled: Bool

    var body: some View {
        HStack(spacing: 4) {
            if weatherEnabled {
                FeatureIcon(systemName: "cloud.sun.fill", color: .blue)
            }
            if eventEnabled {
                FeatureIcon(systemName: "calendar", color: .purple)
            }
        }
    }
}

private struct FeatureIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.caption2)
            .foregroundStyle(color.opacity(0.7))
    }
}

// MARK: - Preview

#Preview("アラーム行") {
    List {
        AlarmRowView(
            alarm: .preview,
            calculation: .previewWithAdjustments,
            onToggle: {}
        )

        AlarmRowView(
            alarm: {
                let calendar = Calendar.current
                let time = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
                return SmartAlarm(
                    baseTime: time,
                    label: "週末アラーム",
                    isEnabled: true,
                    repeatDays: [0, 6],
                    weatherAdjustmentEnabled: false,
                    eventAdjustmentEnabled: false
                )
            }(),
            calculation: .previewNoAdjustments,
            onToggle: {}
        )

        AlarmRowView(
            alarm: {
                let calendar = Calendar.current
                let time = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!
                let alarm = SmartAlarm(
                    baseTime: time,
                    label: "",
                    isEnabled: false,
                    repeatDays: []
                )
                return alarm
            }(),
            calculation: nil,
            onToggle: {}
        )
    }
}
