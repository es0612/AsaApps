//
//  PlanScheduleEditorView.swift
//  AsaWorkoutPlanner
//
//  プランスケジュール編集画面
//  曜日ベースのトレーニング計画設定
//

import SwiftUI
import AsaUIKit

struct PlanScheduleEditorView: View {
    // MARK: - Properties

    @Bindable var plan: WorkoutPlan
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDays: Set<WeekDay>
    @State private var estimatedHours = 0
    @State private var estimatedMinutes = 0

    // MARK: - Initialization

    init(plan: WorkoutPlan) {
        self.plan = plan
        self._selectedDays = State(initialValue: Set(plan.scheduledDays))

        let totalMinutes = Int(plan.estimatedDuration)
        self._estimatedHours = State(initialValue: totalMinutes / 60)
        self._estimatedMinutes = State(initialValue: totalMinutes % 60)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // スケジュール設定セクション
                    scheduleSection

                    // 推定時間設定セクション
                    durationSection

                    // 概要セクション
                    summarySection
                }
                .padding()
            }
            .navigationTitle("スケジュール設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSchedule()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Components

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("トレーニング曜日")
                .font(.headline)

            Text("このプランを実施する曜日を選択してください")
                .font(.caption)
                .foregroundColor(Color(AsaColors.mutedSage))

            AsaCard {
                VStack(spacing: 12) {
                    ForEach(WeekDay.allCases, id: \.self) { day in
                        weekDayRow(day)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func weekDayRow(_ day: WeekDay) -> some View {
        Button {
            toggleDay(day)
        } label: {
            HStack {
                // 曜日アイコン
                ZStack {
                    Circle()
                        .fill(selectedDays.contains(day) ?
                            Color(AsaColors.coffeeBrown) :
                            Color(AsaColors.mutedSage).opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(day.shortName)
                        .font(.headline)
                        .foregroundColor(selectedDays.contains(day) ? .white : Color(AsaColors.mutedSage))
                }

                // 曜日名
                Text(day.rawValue)
                    .font(.body)
                    .foregroundColor(Color(AsaColors.darkSlate))

                Spacer()

                // チェックマーク
                if selectedDays.contains(day) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(selectedDays.contains(day) ?
                Color(AsaColors.softCream).opacity(0.3) :
                Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("推定トレーニング時間")
                .font(.headline)

            Text("1セッションあたりの推定時間を設定してください")
                .font(.caption)
                .foregroundColor(Color(AsaColors.mutedSage))

            AsaCard {
                HStack(spacing: 20) {
                    // 時間
                    VStack {
                        Text("時間")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))

                        Picker("時間", selection: $estimatedHours) {
                            ForEach(0..<5) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 120)
                    }

                    Text("時間")
                        .font(.headline)

                    // 分
                    VStack {
                        Text("分")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))

                        Picker("分", selection: $estimatedMinutes) {
                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 120)
                    }

                    Text("分")
                        .font(.headline)
                }
                .padding()
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("週間概要")
                .font(.headline)

            AsaCard {
                VStack(spacing: 16) {
                    // 週間トレーニング日数
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                        Text("週間トレーニング日数")
                            .font(.subheadline)
                        Spacer()
                        Text("\(selectedDays.count)日")
                            .font(.headline)
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                    }

                    Divider()

                    // 週間推定時間
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                        Text("週間推定時間")
                            .font(.subheadline)
                        Spacer()
                        Text(weeklyDurationText)
                            .font(.headline)
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                    }

                    // スケジュール表示
                    if !selectedDays.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("選択された曜日")
                                .font(.caption)
                                .foregroundColor(Color(AsaColors.mutedSage))

                            HStack(spacing: 8) {
                                ForEach(sortedSelectedDays, id: \.self) { day in
                                    Text(day.shortName)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Color(AsaColors.coffeeBrown))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            // 推奨事項
            if selectedDays.count < 2 {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                        .font(.caption)

                    Text("週2回以上のトレーニングを推奨します")
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
            } else if selectedDays.count > 5 {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)

                    Text("十分な休息日を確保してください")
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var sortedSelectedDays: [WeekDay] {
        selectedDays.sorted { $0.dayNumber < $1.dayNumber }
    }

    private var weeklyDurationText: String {
        let totalMinutes = (estimatedHours * 60 + estimatedMinutes) * selectedDays.count

        if totalMinutes == 0 {
            return "未設定"
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)時間\(minutes)分"
        } else if hours > 0 {
            return "\(hours)時間"
        } else {
            return "\(minutes)分"
        }
    }

    // MARK: - Methods

    private func toggleDay(_ day: WeekDay) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }

    private func saveSchedule() {
        // スケジュールを保存
        plan.scheduledDays = Array(selectedDays)
        plan.estimatedDuration = TimeInterval(estimatedHours * 60 + estimatedMinutes)
        plan.updatedAt = Date()

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let plan = WorkoutPlan(
        name: "上半身トレーニング",
        description: "胸、背中、肩を鍛えるプログラム",
        difficulty: .intermediate,
        category: .strength
    )

    return PlanScheduleEditorView(plan: plan)
}
