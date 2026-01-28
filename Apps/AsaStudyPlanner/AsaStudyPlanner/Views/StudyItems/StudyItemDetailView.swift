import SwiftUI
import SwiftData

struct StudyItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: StudyItem

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // 基本情報セクション
            Section {
                HStack {
                    Text(item.category.emoji)
                        .font(.system(size: 48))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.title2.bold())
                        Text(item.category.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color.clear)

                if let description = item.itemDescription, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            // ステータスセクション
            Section("ステータス") {
                LabeledContent("難易度") {
                    HStack {
                        Image(systemName: item.difficulty.icon)
                            .foregroundStyle(item.difficulty.color)
                        Text(item.difficulty.displayName)
                    }
                }

                LabeledContent("習熟度") {
                    VStack(alignment: .trailing) {
                        Text(item.masteryLabel)
                        ProgressView(value: item.masteryLevel)
                            .frame(width: 100)
                    }
                }

                LabeledContent("推定時間") {
                    Text("\(item.estimatedMinutes)分")
                }

                if let targetDate = item.targetDate {
                    LabeledContent("目標期限") {
                        VStack(alignment: .trailing) {
                            Text(targetDate, style: .date)
                            if let days = item.daysUntilTarget {
                                Text(days < 0 ? "期限切れ" : "あと\(days)日")
                                    .font(.caption)
                                    .foregroundStyle(days < 0 ? .red : .secondary)
                            }
                        }
                    }
                }
            }

            // 学習統計セクション
            Section("学習統計") {
                LabeledContent("総学習時間") {
                    Text("\(item.totalStudyMinutes)分")
                }

                LabeledContent("セッション数") {
                    Text("\(item.sessionCount)回")
                }

                if let nextReview = item.nextReviewDate {
                    LabeledContent("次回復習") {
                        VStack(alignment: .trailing) {
                            Text(nextReview, style: .date)
                            if item.needsReview {
                                Text("復習が必要")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            // AI最適化セクション
            Section("AI最適化") {
                LabeledContent("優先度スコア") {
                    HStack {
                        PriorityBadge(score: item.aiPriorityScore)
                        Text(String(format: "%.0f%%", item.aiPriorityScore * 100))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if item.aiConfidenceScore > 0 {
                    LabeledContent("信頼度") {
                        Text(String(format: "%.0f%%", item.aiConfidenceScore * 100))
                    }
                }

                if !item.aiReasons.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI分析理由")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(item.aiReasons, id: \.self) { reason in
                            Text("• \(reason)")
                                .font(.caption)
                        }
                    }
                }
            }

            // アクションセクション
            Section {
                Button {
                    // TODO: 学習セッション開始
                } label: {
                    Label("学習を開始", systemImage: "play.fill")
                }
                .tint(.green)

                if item.needsReview {
                    Button {
                        // TODO: 復習セッション開始
                    } label: {
                        Label("復習を開始", systemImage: "arrow.clockwise")
                    }
                    .tint(.blue)
                }

                if !item.isCompleted {
                    Button {
                        item.markAsCompleted()
                    } label: {
                        Label("完了としてマーク", systemImage: "checkmark.circle")
                    }
                    .tint(Color("AsaCoffeeBrown"))
                }
            }

            // 危険なアクション
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditStudyItemView(item: item)
        }
        .alert("学習項目を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                modelContext.delete(item)
            }
        } message: {
            Text("「\(item.title)」を削除しますか？この操作は取り消せません。")
        }
    }
}

// MARK: - Edit Study Item View

struct EditStudyItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: StudyItem

    @State private var title: String
    @State private var description: String
    @State private var category: StudyCategory
    @State private var difficulty: DifficultyLevel
    @State private var estimatedMinutes: Int
    @State private var hasTargetDate: Bool
    @State private var targetDate: Date

    init(item: StudyItem) {
        self.item = item
        _title = State(initialValue: item.title)
        _description = State(initialValue: item.itemDescription ?? "")
        _category = State(initialValue: item.category)
        _difficulty = State(initialValue: item.difficulty)
        _estimatedMinutes = State(initialValue: item.estimatedMinutes)
        _hasTargetDate = State(initialValue: item.targetDate != nil)
        _targetDate = State(initialValue: item.targetDate ?? Date().addingTimeInterval(7 * 24 * 60 * 60))
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("タイトル", text: $title)
                    TextField("説明（任意）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(StudyCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }

                Section("難易度") {
                    Picker("難易度", selection: $difficulty) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("推定学習時間") {
                    Stepper("\(estimatedMinutes)分", value: $estimatedMinutes, in: 5...480, step: 5)
                }

                Section("目標期限") {
                    Toggle("期限を設定", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("期限", selection: $targetDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("編集")
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
                    .disabled(!isValid)
                }
            }
        }
    }

    private func saveChanges() {
        item.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        item.itemDescription = description.isEmpty ? nil : description
        item.category = category
        item.difficulty = difficulty
        item.estimatedMinutes = estimatedMinutes
        item.targetDate = hasTargetDate ? targetDate : nil
        item.updatedAt = Date()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        StudyItemDetailView(item: StudyItem(
            title: "Swift並行処理",
            description: "async/await、Actor、Sendableの学習",
            category: .programming,
            difficulty: .hard,
            estimatedMinutes: 60,
            targetDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        ))
    }
    .modelContainer(for: [
        StudyItem.self,
        StudySession.self,
        StudyPlan.self,
        LearningAnalytics.self,
        UserLearningProfile.self
    ], inMemory: true)
}
