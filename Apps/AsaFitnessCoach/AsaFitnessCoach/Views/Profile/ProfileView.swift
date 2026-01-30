//
//  ProfileView.swift
//  AsaFitnessCoach
//
//  プロフィール画面
//

import SwiftUI

struct ProfileView: View {
    // MARK: - Properties

    @Bindable var viewModel: FitnessCoachViewModel
    @State private var showEditProfile = false
    @State private var showGoalSettings = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if let profile = viewModel.userProfile {
                    // プロフィールセクション
                    profileSection(profile)

                    // 目標設定セクション
                    goalSection(profile)

                    // 機器設定セクション
                    equipmentSection(profile)

                    // スケジュールセクション
                    scheduleSection(profile)

                    // HealthKitセクション
                    healthKitSection

                    // 統計セクション
                    statsSection
                } else {
                    Section {
                        Button("プロフィールを設定") {
                            showEditProfile = true
                        }
                    }
                }
            }
            .navigationTitle("プロフィール")
            .sheet(isPresented: $showEditProfile) {
                if let profile = viewModel.userProfile {
                    EditProfileView(viewModel: viewModel, profile: profile)
                } else {
                    OnboardingView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showGoalSettings) {
                if let profile = viewModel.userProfile {
                    GoalSettingView(viewModel: viewModel, profile: profile)
                }
            }
        }
    }

    // MARK: - Sections

    private func profileSection(_ profile: UserProfile) -> some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Image(systemName: profile.fitnessLevel.icon)
                        Text(profile.fitnessLevel.rawValue)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showEditProfile = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func goalSection(_ profile: UserProfile) -> some View {
        Section("目標") {
            HStack {
                Image(systemName: profile.primaryGoal.icon)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.primaryGoal.rawValue)
                        .font(.headline)

                    Text(profile.primaryGoal.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showGoalSettings = true
                } label: {
                    Text("変更")
                        .font(.subheadline)
                }
            }
        }
    }

    private func equipmentSection(_ profile: UserProfile) -> some View {
        Section("利用可能な器具") {
            if profile.availableEquipment.isEmpty || profile.availableEquipment == [.none] {
                HStack {
                    Image(systemName: "hand.raised")
                        .foregroundStyle(.secondary)
                    Text("自重トレーニングのみ")
                        .foregroundStyle(.secondary)
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(profile.availableEquipment, id: \.self) { equipment in
                        VStack(spacing: 4) {
                            Image(systemName: equipment.icon)
                                .font(.title3)
                            Text(equipment.rawValue)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            Button {
                showEditProfile = true
            } label: {
                Label("器具を編集", systemImage: "square.and.pencil")
            }
        }
    }

    private func scheduleSection(_ profile: UserProfile) -> some View {
        Section("スケジュール") {
            HStack {
                Label("1回のワークアウト", systemImage: "clock")
                Spacer()
                Text("\(profile.preferredWorkoutDuration)分")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("週のトレーニング", systemImage: "calendar")
                Spacer()
                Text("\(profile.workoutDaysPerWeek)日")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var healthKitSection: some View {
        Section("HealthKit") {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.healthKitService_.isAuthorized ? "連携済み" : "未連携")
                        .font(.headline)

                    Text(viewModel.healthKitService_.authorizationStatusDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !viewModel.healthKitService_.isAuthorized {
                    Button("連携する") {
                        Task {
                            await viewModel.requestHealthKitAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }

    private var statsSection: some View {
        Section("累計実績") {
            if let stats = viewModel.monthlyStats {
                HStack {
                    Label("今月のワークアウト", systemImage: "figure.run")
                    Spacer()
                    Text("\(stats.workoutCount)回")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("合計時間", systemImage: "timer")
                    Spacer()
                    Text(stats.displayDuration)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("消費カロリー", systemImage: "flame")
                    Spacer()
                    Text("\(Int(stats.totalCalories)) kcal")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("総ボリューム", systemImage: "scalemass")
                    Spacer()
                    Text("\(Int(stats.totalVolume)) kg")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("まだデータがありません")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Bindable var viewModel: FitnessCoachViewModel
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var fitnessLevel: FitnessLevel = .beginner
    @State private var preferredDuration: Int = 30
    @State private var workoutDaysPerWeek: Int = 3
    @State private var availableEquipment: Set<Equipment> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("名前", text: $name)

                    Picker("体力レベル", selection: $fitnessLevel) {
                        ForEach(FitnessLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }

                Section("スケジュール") {
                    Picker("ワークアウト時間", selection: $preferredDuration) {
                        ForEach([15, 20, 30, 45, 60], id: \.self) { duration in
                            Text("\(duration)分").tag(duration)
                        }
                    }

                    Picker("週のトレーニング日数", selection: $workoutDaysPerWeek) {
                        ForEach(1...7, id: \.self) { days in
                            Text("\(days)日").tag(days)
                        }
                    }
                }

                Section("利用可能な器具") {
                    ForEach(Equipment.allCases.filter { $0 != .none }, id: \.self) { equipment in
                        Toggle(equipment.rawValue, isOn: Binding(
                            get: { availableEquipment.contains(equipment) },
                            set: { isOn in
                                if isOn {
                                    availableEquipment.insert(equipment)
                                } else {
                                    availableEquipment.remove(equipment)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }

    private func loadProfile() {
        name = profile.name
        fitnessLevel = profile.fitnessLevel
        preferredDuration = profile.preferredWorkoutDuration
        workoutDaysPerWeek = profile.workoutDaysPerWeek
        availableEquipment = Set(profile.availableEquipment.filter { $0 != .none })
    }

    private func saveChanges() {
        profile.name = name
        profile.fitnessLevel = fitnessLevel
        profile.preferredWorkoutDuration = preferredDuration
        profile.workoutDaysPerWeek = workoutDaysPerWeek
        profile.availableEquipment = availableEquipment.isEmpty ? [.none] : Array(availableEquipment)

        viewModel.updateUserProfile(profile)
        dismiss()
    }
}

// MARK: - Goal Setting View

struct GoalSettingView: View {
    @Bindable var viewModel: FitnessCoachViewModel
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGoal: FitnessGoalType = .generalFitness

    var body: some View {
        NavigationStack {
            List {
                ForEach(FitnessGoalType.allCases, id: \.self) { goal in
                    Button {
                        selectedGoal = goal
                    } label: {
                        HStack {
                            Image(systemName: goal.icon)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(goal.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("目標設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        profile.primaryGoal = selectedGoal
                        viewModel.updateUserProfile(profile)
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedGoal = profile.primaryGoal
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView(viewModel: FitnessCoachViewModel())
}
