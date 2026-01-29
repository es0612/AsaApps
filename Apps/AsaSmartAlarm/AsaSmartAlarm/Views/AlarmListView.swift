//
//  AlarmListView.swift
//  AsaSmartAlarm
//
//  アラーム一覧画面
//

import SwiftUI

// MARK: - アラーム一覧ビュー

/// メインのアラーム一覧画面
struct AlarmListView: View {
    // MARK: - Properties

    var viewModel: AlarmViewModel
    let weatherViewModel: WeatherViewModel

    // MARK: - Body

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 次のアラームカード
                    if let nextAlarm = viewModel.nextAlarm {
                        NextAlarmCard(
                            alarm: nextAlarm,
                            calculation: viewModel.calculation(for: nextAlarm)
                        )
                        .padding(.horizontal)
                    }

                    // 天気カード
                    WeatherCardView(
                        forecast: weatherViewModel.morningForecast,
                        isLoading: weatherViewModel.isLoading,
                        onRefresh: {
                            Task {
                                await weatherViewModel.refreshWeather()
                            }
                        }
                    )
                    .padding(.horizontal)

                    // アラーム一覧
                    AlarmListSection(
                        alarms: viewModel.alarms,
                        calculations: viewModel.alarmCalculations,
                        onToggle: { alarm in
                            Task {
                                await viewModel.toggleAlarm(alarm)
                            }
                        },
                        onDelete: { alarm in
                            Task {
                                await viewModel.deleteAlarm(alarm)
                            }
                        },
                        onSelect: { alarm in
                            viewModel.selectedAlarm = alarm
                        }
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("アラーム")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddAlarm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $bindableViewModel.showingAddAlarm) {
                AddAlarmView(viewModel: viewModel)
            }
            .sheet(item: $bindableViewModel.selectedAlarm) { alarm in
                AlarmDetailView(
                    alarm: alarm,
                    calculation: viewModel.calculation(for: alarm),
                    onSave: { updatedAlarm in
                        Task {
                            await viewModel.updateAlarm(updatedAlarm)
                        }
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteAlarm(alarm)
                        }
                    }
                )
            }
            .sheet(isPresented: $bindableViewModel.showingSettings) {
                SettingsView(settings: viewModel.settings)
            }
            .refreshable {
                await viewModel.loadData()
                await weatherViewModel.refreshWeather()
            }
        }
    }
}

// MARK: - 次のアラームカード

private struct NextAlarmCard: View {
    let alarm: SmartAlarm
    let calculation: AlarmCalculationResult?

    var body: some View {
        VStack(spacing: 12) {
            // 見出し
            HStack {
                Label("次のアラーム", systemImage: "alarm.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if let calc = calculation {
                    Text(relativeTimeString(from: calc.adjustedTime))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // 時刻
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(displayTime)
                    .font(.system(size: 56, weight: .light, design: .rounded))

                if let calc = calculation, calc.hasAdjustments {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("(\(alarm.timeString)から)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .strikethrough()

                        Text(calc.timeChangeDescription)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                    }
                }
            }

            // ラベル
            if !alarm.label.isEmpty {
                Text(alarm.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // 調整情報
            if let calc = calculation, calc.hasAdjustments {
                Divider()

                AdjustmentRuleSummary(calculation: calc)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var displayTime: String {
        if let calc = calculation {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: calc.adjustedTime)
        }
        return alarm.timeString
    }

    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - アラーム一覧セクション

private struct AlarmListSection: View {
    let alarms: [SmartAlarm]
    let calculations: [UUID: AlarmCalculationResult]
    let onToggle: (SmartAlarm) -> Void
    let onDelete: (SmartAlarm) -> Void
    let onSelect: (SmartAlarm) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // セクションヘッダー
            HStack {
                Label("アラーム", systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(alarms.count)件")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if alarms.isEmpty {
                EmptyAlarmView()
            } else {
                VStack(spacing: 0) {
                    ForEach(alarms) { alarm in
                        VStack(spacing: 0) {
                            AlarmRowView(
                                alarm: alarm,
                                calculation: calculations[alarm.id],
                                onToggle: { onToggle(alarm) }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(alarm)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    onDelete(alarm)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }

                            if alarm.id != alarms.last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

// MARK: - 空のアラームビュー

private struct EmptyAlarmView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "alarm")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("アラームがありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("右上の＋ボタンからアラームを追加してください")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview("アラーム一覧") {
    AlarmListView(
        viewModel: .preview,
        weatherViewModel: .preview
    )
}
