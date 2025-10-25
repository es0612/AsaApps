//
//  ExerciseLibraryView.swift
//  AsaWorkoutPlanner
//
//  エクササイズライブラリ画面
//  プリセットエクササイズの閲覧と選択
//

import SwiftUI
import AsaUIKit

struct ExerciseLibraryView: View {
    // MARK: - Properties

    let plan: WorkoutPlan
    @Bindable var viewModel: WorkoutPlannerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ExerciseCategory = .chest
    @State private var searchText = ""
    @State private var selectedExercise: ExerciseTemplate?
    @State private var showingExerciseDetail = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 検索バー
                searchBar

                // カテゴリータブ
                categoryPicker

                // エクササイズリスト
                exerciseList
            }
            .navigationTitle("エクササイズライブラリ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedExercise) { template in
                ExerciseDetailSheet(
                    template: template,
                    onAdd: { exercise in
                        plan.addExercise(exercise)
                        dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Components

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(AsaColors.mutedSage))

            TextField("エクササイズを検索", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(AsaColors.mutedSage))
                }
            }
        }
        .padding()
        .background(Color(AsaColors.softCream).opacity(0.3))
        .cornerRadius(10)
        .padding()
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ExerciseCategory.allCases.filter { $0 != .flexibility }, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            selectedCategory = category
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredExercises, id: \.name) { template in
                    ExerciseLibraryCard(
                        template: template,
                        onTap: {
                            selectedExercise = template
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Computed Properties

    private var filteredExercises: [ExerciseTemplate] {
        if searchText.isEmpty {
            return PresetExerciseLibrary.exercises(for: selectedCategory)
        } else {
            return PresetExerciseLibrary.search(searchText)
        }
    }
}

// MARK: - Supporting Views

struct CategoryTab: View {
    let category: ExerciseCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title3)

                Text(category.rawValue)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : Color(AsaColors.mutedSage))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(AsaColors.coffeeBrown) : Color(AsaColors.softCream).opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseLibraryCard: View {
    let template: ExerciseTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            AsaCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack {
                                Image(systemName: template.category.icon)
                                    .foregroundColor(Color(template.category.color))

                                Text(template.category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(Color(AsaColors.mutedSage))
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(Color(AsaColors.mutedSage))
                    }

                    // ターゲット筋肉
                    if !template.targetMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ターゲット筋肉")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(template.targetMuscles, id: \.self) { muscle in
                                        Text(muscle.rawValue)
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(AsaColors.softCream).opacity(0.5))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }

                    // 推奨設定
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("セット")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))
                            Text("\(template.sets)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.duration != nil ? "時間" : "レップ")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))
                            Text(template.duration != nil ? "\(Int(template.duration! / 60))分" : "\(template.reps)回")
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("休憩")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))
                            Text("\(Int(template.restTime))秒")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }

                    // 説明（一行のみプレビュー）
                    if let instructions = template.instructions {
                        Text(instructions)
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                            .lineLimit(2)
                    }
                }
                .padding()
            }
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseDetailSheet: View {
    let template: ExerciseTemplate
    let onAdd: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var customSets: Int
    @State private var customReps: Int
    @State private var customWeight: String = ""
    @State private var customRestTime: Int

    init(template: ExerciseTemplate, onAdd: @escaping (Exercise) -> Void) {
        self.template = template
        self.onAdd = onAdd
        _customSets = State(initialValue: template.sets)
        _customReps = State(initialValue: template.reps)
        _customRestTime = State(initialValue: Int(template.restTime))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // ヘッダー
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: template.category.icon)
                                .font(.largeTitle)
                                .foregroundColor(Color(template.category.color))

                            Spacer()

                            Text(template.category.rawValue)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(template.category.color).opacity(0.2))
                                .cornerRadius(12)
                        }

                        Text(template.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }

                    // ターゲット筋肉
                    if !template.targetMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ターゲット筋肉")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(template.targetMuscles, id: \.self) { muscle in
                                    Text(muscle.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(AsaColors.softCream).opacity(0.5))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }

                    // 実施方法
                    if let instructions = template.instructions {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("実施方法")
                                .font(.headline)

                            Text(instructions)
                                .font(.body)
                                .foregroundColor(Color(AsaColors.darkSlate))
                        }
                    }

                    // ポイント
                    if let tips = template.tips {
                        AsaCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text("ポイント")
                                        .font(.headline)
                                }

                                Text(tips)
                                    .font(.body)
                                    .foregroundColor(Color(AsaColors.darkSlate))
                            }
                            .padding()
                        }
                    }

                    Divider()

                    // カスタマイズ設定
                    VStack(alignment: .leading, spacing: 16) {
                        Text("トレーニング設定")
                            .font(.headline)

                        // セット数
                        VStack(alignment: .leading, spacing: 8) {
                            Text("セット数: \(customSets)")
                                .font(.subheadline)

                            Stepper("", value: $customSets, in: 1...10)
                                .labelsHidden()
                        }

                        // レップ数
                        if template.duration == nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("レップ数: \(customReps)")
                                    .font(.subheadline)

                                Stepper("", value: $customReps, in: 1...50)
                                    .labelsHidden()
                            }

                            // 重量
                            VStack(alignment: .leading, spacing: 8) {
                                Text("重量 (kg) - オプション")
                                    .font(.subheadline)

                                TextField("重量を入力", text: $customWeight)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        // 休憩時間
                        VStack(alignment: .leading, spacing: 8) {
                            Text("休憩時間: \(customRestTime)秒")
                                .font(.subheadline)

                            Stepper("", value: $customRestTime, in: 15...300, step: 15)
                                .labelsHidden()
                        }
                    }

                    // 追加ボタン
                    AsaButton(
                        title: "プランに追加",
                        action: {
                            addExercise()
                        },
                        color: AsaColors.coffeeBrown
                    )
                }
                .padding()
            }
            .navigationTitle("エクササイズ詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addExercise() {
        let exercise = template.toExercise()
        exercise.sets = customSets
        exercise.reps = customReps
        exercise.restTime = TimeInterval(customRestTime)

        if let weight = Double(customWeight), weight > 0 {
            exercise.weight = weight
        }

        onAdd(exercise)
        dismiss()
    }
}

// MARK: - FlowLayout（水平折り返しレイアウト）

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size = CGSize.zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
