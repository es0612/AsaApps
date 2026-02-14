import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// ゴミ出しカレンダー画面
struct GarbageScheduleView: View {
    @Bindable var viewModel: GarbageScheduleViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Today & Tomorrow
                VStack(alignment: .leading, spacing: 8) {
                    Text("今日のゴミ出し")
                        .font(.headline)
                        .foregroundStyle(AsaColors.darkSlate)

                    if viewModel.todaysGarbage.isEmpty {
                        infoCard("今日の収集はありません", iconName: "checkmark.circle")
                    } else {
                        ForEach(viewModel.todaysGarbage) { schedule in
                            garbageRow(schedule)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("明日のゴミ出し")
                        .font(.headline)
                        .foregroundStyle(AsaColors.darkSlate)

                    if viewModel.tomorrowsGarbage.isEmpty {
                        infoCard("明日の収集はありません", iconName: "checkmark.circle")
                    } else {
                        ForEach(viewModel.tomorrowsGarbage) { schedule in
                            garbageRow(schedule)
                        }
                    }
                }

                Divider()

                // MARK: - Weekly Schedule
                VStack(alignment: .leading, spacing: 8) {
                    Text("週間スケジュール")
                        .font(.headline)
                        .foregroundStyle(AsaColors.darkSlate)

                    let grouped = Dictionary(grouping: viewModel.schedules) { $0.weekday }
                    let sorted = grouped.sorted { $0.key < $1.key }

                    ForEach(sorted, id: \.key) { weekday, schedules in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(schedules.first?.weekdayText ?? "")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(AsaColors.coffeeBrown)

                            ForEach(schedules) { schedule in
                                HStack(spacing: 8) {
                                    Image(systemName: schedule.garbageType.iconName)
                                        .frame(width: 20)
                                    Text(schedule.garbageType.rawValue)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(schedule.scheduleDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // MARK: - Reminder Toggle
                Toggle(isOn: $viewModel.isReminderEnabled) {
                    Label("前夜リマインダー", systemImage: "bell.badge")
                }
                .tint(AsaColors.coffeeBrown)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onChange(of: viewModel.isReminderEnabled) { _, _ in
                    Task {
                        await viewModel.toggleReminder()
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ゴミ出しカレンダー")
        .onAppear {
            viewModel.loadSchedules()
        }
    }

    private func garbageRow(_ schedule: GarbageSchedule) -> some View {
        HStack(spacing: 12) {
            Image(systemName: schedule.garbageType.iconName)
                .font(.title3)
                .frame(width: 32)
            VStack(alignment: .leading) {
                Text(schedule.garbageType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if !schedule.note.isEmpty {
                    Text(schedule.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(schedule.collectionHour):\(String(format: "%02d", schedule.collectionMinute))まで")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func infoCard(_ message: String, iconName: String) -> some View {
        HStack {
            Image(systemName: iconName)
                .foregroundStyle(.green)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
