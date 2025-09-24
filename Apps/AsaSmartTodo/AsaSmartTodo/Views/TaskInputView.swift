import SwiftUI
import AsaUIKit

struct TaskInputView: View {
    @EnvironmentObject private var viewModel: SmartTodoViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: TaskCategory = .other
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var showingPrediction = false

    // リアルタイム予測用
    @State private var realtimePrediction: PredictionResult?
    @State private var predictionTimer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.softCream.opacity(0.3)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // タイトル入力
                        VStack(alignment: .leading, spacing: 8) {
                            Label("タスク名", systemImage: "pencil")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)

                            TextField("タスクを入力", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: title) { _, _ in
                                    schedulePrediction()
                                }
                        }

                        // 説明入力
                        VStack(alignment: .leading, spacing: 8) {
                            Label("詳細説明（任意）", systemImage: "text.alignleft")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)

                            TextEditor(text: $description)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: description) { _, _ in
                                    schedulePrediction()
                                }
                        }

                        // カテゴリ選択
                        VStack(alignment: .leading, spacing: 8) {
                            Label("カテゴリ", systemImage: "folder")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)

                            Picker("カテゴリ", selection: $category) {
                                ForEach(TaskCategory.allCases, id: \.self) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: category) { _, _ in
                                schedulePrediction()
                            }
                        }

                        // 期限設定
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $hasDueDate) {
                                Label("期限を設定", systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(AsaColors.mutedSage)
                            }

                            if hasDueDate {
                                DatePicker(
                                    "期限",
                                    selection: $dueDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(CompactDatePickerStyle())
                                .onChange(of: dueDate) { _, _ in
                                    schedulePrediction()
                                }
                            }
                        }

                        // AI予測表示（リアルタイム）
                        if let prediction = realtimePrediction, !title.isEmpty {
                            RealtimePredictionCard(prediction: prediction)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        // 追加ボタン
                        AsaButton(
                            title: viewModel.isPredicting ? "分析中..." : "タスクを追加",
                            action: addTask,
                            color: AsaColors.coffeeBrown,
                            isLoading: viewModel.isPredicting
                        )
                        .disabled(title.isEmpty || viewModel.isPredicting)
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("新しいタスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
    }

    // MARK: - Methods

    private func schedulePrediction() {
        // 既存のタイマーをキャンセル
        predictionTimer?.invalidate()

        // 0.5秒後に予測を実行（入力の度に実行されないように）
        predictionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task {
                await performRealtimePrediction()
            }
        }
    }

    @MainActor
    private func performRealtimePrediction() async {
        guard !title.isEmpty else {
            withAnimation {
                realtimePrediction = nil
            }
            return
        }

        // 仮のタスクを作成して予測
        let tempTask = SmartTask(
            title: title,
            description: description.isEmpty ? nil : description,
            category: category,
            dueDate: hasDueDate ? dueDate : nil
        )

        let predictor = await TaskPriorityPredictor()
        let prediction = await predictor.predictPriority(for: tempTask)

        withAnimation(.easeInOut(duration: 0.3)) {
            realtimePrediction = prediction
        }
    }

    private func addTask() {
        Task {
            await viewModel.addTask(
                title: title,
                description: description.isEmpty ? nil : description,
                category: category,
                dueDate: hasDueDate ? dueDate : nil
            )
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Realtime Prediction Card

struct RealtimePredictionCard: View {
    let prediction: PredictionResult

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(AsaColors.mocha)
                    Text("AI優先度予測")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    Text("\(Int(prediction.confidenceScore * 100))%")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                // 予測優先度
                HStack(spacing: 16) {
                    ForEach([TaskPriority.high, .medium, .low], id: \.self) { priority in
                        PriorityOption(
                            priority: priority,
                            isSelected: priority == prediction.suggestedPriority
                        )
                    }
                }

                // 理由
                if !prediction.reasoning.isEmpty {
                    Text(prediction.reasoning)
                        .font(.caption)
                        .foregroundColor(AsaColors.darkSlate.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 特徴量インジケータ
                FeatureIndicators(features: prediction.features)
            }
            .padding()
        }
    }
}

// MARK: - Priority Option

struct PriorityOption: View {
    let priority: TaskPriority
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: isSelected ? 16 : 12, height: isSelected ? 16 : 12)
                .overlay(
                    Circle()
                        .stroke(priorityColor.opacity(0.5), lineWidth: isSelected ? 3 : 0)
                        .frame(width: 24, height: 24)
                )

            Text(priority.displayName)
                .font(.caption2)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? priorityColor : AsaColors.mutedSage)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var priorityColor: Color {
        switch priority {
        case .high:
            return Color.red
        case .medium:
            return AsaColors.coffeeBrown
        case .low:
            return AsaColors.mutedSage
        }
    }
}

// MARK: - Feature Indicators

struct FeatureIndicators: View {
    let features: TaskFeatures

    var body: some View {
        HStack(spacing: 8) {
            // 文字数インジケータ
            FeatureBadge(
                icon: "textformat.size",
                value: "\(features.titleWordCount)語",
                color: AsaColors.mutedSage
            )

            // 期限インジケータ
            if let days = features.daysUntilDue {
                FeatureBadge(
                    icon: "calendar",
                    value: days == 0 ? "今日" : "\(days)日",
                    color: days <= 3 ? Color.red : AsaColors.coffeeBrown
                )
            }

            // 朝活インジケータ
            if features.createdHour >= 5 && features.createdHour < 7 {
                FeatureBadge(
                    icon: "sunrise",
                    value: "朝活",
                    color: Color.orange
                )
            }
        }
    }
}

// MARK: - Feature Badge

struct FeatureBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(.system(size: 10))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Preview

#Preview {
    TaskInputView()
        .environmentObject(SmartTodoViewModel())