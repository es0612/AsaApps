//
//  OnboardingView.swift
//  AsaFitnessCoach
//
//  オンボーディング画面
//

import SwiftUI

struct OnboardingView: View {
    // MARK: - Properties

    @Bindable var viewModel: FitnessCoachViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var name = ""
    @State private var fitnessLevel: FitnessLevel = .beginner
    @State private var primaryGoal: FitnessGoalType = .generalFitness
    @State private var availableEquipment: Set<Equipment> = []
    @State private var preferredDuration = 30
    @State private var workoutDaysPerWeek = 3

    private let durationOptions = [15, 20, 30, 45, 60]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack {
                // 進捗インジケーター
                ProgressIndicator(currentStep: currentStep, totalSteps: 5)
                    .padding()

                // コンテンツ
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    fitnessLevelStep.tag(1)
                    goalStep.tag(2)
                    equipmentStep.tag(3)
                    scheduleStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // ナビゲーションボタン
                HStack {
                    if currentStep > 0 {
                        Button("戻る") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if currentStep < 4 {
                        Button("次へ") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(currentStep == 0 && name.isEmpty)
                    } else {
                        Button("完了") {
                            saveProfile()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("プロフィール設定")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            Text("AsaFitnessCoachへようこそ")
                .font(.title)
                .fontWeight(.bold)

            Text("AIがあなた専属のパーソナルトレーナーに。\n最適化されたワークアウトプランで\n効果的なトレーニングを始めましょう。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            TextField("あなたの名前", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
        }
        .padding()
    }

    private var fitnessLevelStep: some View {
        VStack(spacing: 24) {
            Text("現在の体力レベルは？")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ForEach(FitnessLevel.allCases, id: \.self) { level in
                    SelectableCard(
                        title: level.rawValue,
                        subtitle: level.description,
                        icon: level.icon,
                        isSelected: fitnessLevel == level
                    ) {
                        fitnessLevel = level
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var goalStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("主な目標は？")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    ForEach(FitnessGoalType.allCases, id: \.self) { goal in
                        SelectableCard(
                            title: goal.rawValue,
                            subtitle: goal.description,
                            icon: goal.icon,
                            isSelected: primaryGoal == goal
                        ) {
                            primaryGoal = goal
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }

    private var equipmentStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("利用可能な器具")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("選択しない場合は自重トレーニングを提案します")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Equipment.allCases.filter { $0 != .none }, id: \.self) { equipment in
                        EquipmentToggle(
                            equipment: equipment,
                            isSelected: availableEquipment.contains(equipment)
                        ) {
                            if availableEquipment.contains(equipment) {
                                availableEquipment.remove(equipment)
                            } else {
                                availableEquipment.insert(equipment)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }

    private var scheduleStep: some View {
        VStack(spacing: 32) {
            Text("トレーニングスケジュール")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                Text("1回のワークアウト時間")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(durationOptions, id: \.self) { duration in
                        Button {
                            preferredDuration = duration
                        } label: {
                            Text("\(duration)分")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(preferredDuration == duration ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(preferredDuration == duration ? Color.accentColor : Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            VStack(spacing: 16) {
                Text("週に何日トレーニング？")
                    .font(.headline)

                Picker("週のトレーニング日数", selection: $workoutDaysPerWeek) {
                    ForEach(1...7, id: \.self) { days in
                        Text("\(days)日").tag(days)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Methods

    private func saveProfile() {
        let profile = UserProfile(
            name: name,
            fitnessLevel: fitnessLevel,
            primaryGoal: primaryGoal,
            preferredWorkoutDuration: preferredDuration,
            workoutDaysPerWeek: workoutDaysPerWeek
        )

        profile.availableEquipment = availableEquipment.isEmpty ? [.none] : Array(availableEquipment)

        viewModel.saveUserProfile(profile)
        dismiss()
    }
}

// MARK: - Supporting Views

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.accentColor : Color(.systemGray4))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

struct SelectableCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.accentColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct EquipmentToggle: View {
    let equipment: Equipment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: equipment.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.accentColor)

                Text(equipment.rawValue)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(viewModel: FitnessCoachViewModel())
}
