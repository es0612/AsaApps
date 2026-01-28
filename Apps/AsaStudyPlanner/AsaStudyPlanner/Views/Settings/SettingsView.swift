import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserLearningProfile]

    @State private var showingResetAlert = false

    private var profile: UserLearningProfile {
        if let existing = profiles.first {
            return existing
        }
        let newProfile = UserLearningProfile()
        modelContext.insert(newProfile)
        return newProfile
    }

    var body: some View {
        NavigationStack {
            List {
                // 朝活設定
                Section("朝活設定") {
                    HStack {
                        Text("開始時刻")
                        Spacer()
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { profile.morningStartTime },
                                set: { newValue in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                    profile.morningStartHour = components.hour ?? 5
                                    profile.morningStartMinute = components.minute ?? 30
                                    profile.update()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }

                    Stepper("目標時間: \(profile.morningGoalMinutes)分", value: Binding(
                        get: { profile.morningGoalMinutes },
                        set: { profile.morningGoalMinutes = $0; profile.update() }
                    ), in: 15...180, step: 15)

                    Toggle("朝活リマインダー", isOn: Binding(
                        get: { profile.morningReminderEnabled },
                        set: { profile.morningReminderEnabled = $0; profile.update() }
                    ))
                }

                // 学習目標
                Section("学習目標") {
                    Stepper("1日の目標: \(profile.dailyGoalMinutes)分", value: Binding(
                        get: { profile.dailyGoalMinutes },
                        set: { profile.dailyGoalMinutes = $0; profile.update() }
                    ), in: 30...480, step: 30)

                    Stepper("週間目標: \(profile.weeklyGoalMinutes)分", value: Binding(
                        get: { profile.weeklyGoalMinutes },
                        set: { profile.weeklyGoalMinutes = $0; profile.update() }
                    ), in: 120...2400, step: 60)
                }

                // AI最適化設定
                Section("AI最適化") {
                    Toggle("AI最適化を有効化", isOn: Binding(
                        get: { profile.aiOptimizationEnabled },
                        set: { profile.aiOptimizationEnabled = $0; profile.update() }
                    ))

                    if profile.aiOptimizationEnabled {
                        NavigationLink {
                            OptimizationPresetView(profile: profile)
                        } label: {
                            HStack {
                                Text("最適化モード")
                                Spacer()
                                Text(profile.optimizationPreset.displayName)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // セッション設定
                Section("セッション設定") {
                    Stepper("デフォルト時間: \(profile.defaultSessionMinutes)分", value: Binding(
                        get: { profile.defaultSessionMinutes },
                        set: { profile.defaultSessionMinutes = $0; profile.update() }
                    ), in: 5...120, step: 5)

                    Toggle("休憩リマインダー", isOn: Binding(
                        get: { profile.breakReminderEnabled },
                        set: { profile.breakReminderEnabled = $0; profile.update() }
                    ))

                    if profile.breakReminderEnabled {
                        Stepper("休憩間隔: \(profile.breakIntervalMinutes)分", value: Binding(
                            get: { profile.breakIntervalMinutes },
                            set: { profile.breakIntervalMinutes = $0; profile.update() }
                        ), in: 15...60, step: 5)
                    }
                }

                // 通知設定
                Section("通知") {
                    Toggle("学習リマインダー", isOn: Binding(
                        get: { profile.studyReminderEnabled },
                        set: { profile.studyReminderEnabled = $0; profile.update() }
                    ))

                    Toggle("復習リマインダー", isOn: Binding(
                        get: { profile.reviewReminderEnabled },
                        set: { profile.reviewReminderEnabled = $0; profile.update() }
                    ))

                    Toggle("達成通知", isOn: Binding(
                        get: { profile.achievementNotificationEnabled },
                        set: { profile.achievementNotificationEnabled = $0; profile.update() }
                    ))
                }

                // アプリ情報
                Section("アプリ情報") {
                    LabeledContent("バージョン", value: "1.0.0")
                    LabeledContent("ビルド", value: "1")

                    Link(destination: URL(string: "https://github.com/anthropics/claude-code")!) {
                        HStack {
                            Text("開発者情報")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // データ管理
                Section("データ管理") {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("すべてのデータを削除", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("設定")
            .alert("データを削除", isPresented: $showingResetAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("すべての学習データが削除されます。この操作は取り消せません。")
            }
        }
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: StudyItem.self)
            try modelContext.delete(model: StudySession.self)
            try modelContext.delete(model: StudyPlan.self)
            try modelContext.delete(model: LearningAnalytics.self)
        } catch {
            print("Error deleting data: \(error)")
        }
    }
}

// MARK: - Optimization Preset View

struct OptimizationPresetView: View {
    @Bindable var profile: UserLearningProfile

    var body: some View {
        List {
            Section {
                ForEach(OptimizationPreset.allCases, id: \.self) { preset in
                    Button {
                        profile.optimizationPreset = preset
                        profile.update()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(preset.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if profile.optimizationPreset == preset {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color("AsaCoffeeBrown"))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("プリセット選択")
            } footer: {
                Text("各プリセットは異なる要因の重み付けを行い、学習順序の最適化方法を変更します。")
            }

            // 現在の重み表示
            Section("現在の重み設定") {
                let weights = profile.effectiveWeights

                WeightRow(label: "目標期限", value: weights.targetDateWeight, color: .red)
                WeightRow(label: "難易度×時間帯", value: weights.difficultyTimeWeight, color: .orange)
                WeightRow(label: "習熟度", value: weights.masteryWeight, color: .yellow)
                WeightRow(label: "復習必要度", value: weights.reviewWeight, color: .blue)
                WeightRow(label: "時間帯適性", value: weights.timeOfDayWeight, color: .green)
                WeightRow(label: "前提知識", value: weights.prerequisiteWeight, color: .purple)
            }
        }
        .navigationTitle("最適化モード")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WeightRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            Text(String(format: "%.0f%%", value * 100))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.3))
                    .frame(width: geometry.size.width)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geometry.size.width * value)
                    }
            }
            .frame(width: 80, height: 8)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [
            StudyItem.self,
            StudySession.self,
            StudyPlan.self,
            LearningAnalytics.self,
            UserLearningProfile.self
        ], inMemory: true)
}
