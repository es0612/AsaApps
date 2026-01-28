import SwiftUI
import SwiftData

struct AddStudyItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: StudyCategory = .other
    @State private var difficulty: DifficultyLevel = .medium
    @State private var estimatedMinutes = 30
    @State private var hasTargetDate = false
    @State private var targetDate = Date().addingTimeInterval(7 * 24 * 60 * 60)

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // 基本情報
                Section("基本情報") {
                    TextField("タイトル", text: $title)

                    TextField("説明（任意）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                // カテゴリ
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(StudyCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    // カテゴリプレビュー
                    HStack {
                        Text(category.emoji)
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(category.displayName)
                                .font(.headline)
                            Text("推奨セッション: \(category.recommendedSessionMinutes)分")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // 難易度
                Section("難易度") {
                    Picker("難易度", selection: $difficulty) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            HStack {
                                Image(systemName: level.icon)
                                Text(level.displayName)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)

                    // 難易度情報
                    HStack {
                        Image(systemName: difficulty.icon)
                            .foregroundStyle(difficulty.color)
                        Text(difficultyDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // 学習時間
                Section("推定学習時間") {
                    Stepper("\(estimatedMinutes)分", value: $estimatedMinutes, in: 5...480, step: 5)

                    // 時間スライダー
                    Slider(value: Binding(
                        get: { Double(estimatedMinutes) },
                        set: { estimatedMinutes = Int($0) }
                    ), in: 5...120, step: 5)
                }

                // 目標期限
                Section("目標期限") {
                    Toggle("期限を設定", isOn: $hasTargetDate)

                    if hasTargetDate {
                        DatePicker(
                            "期限",
                            selection: $targetDate,
                            in: Date()...,
                            displayedComponents: .date
                        )

                        // 期限までの日数
                        let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                        Text("あと\(days)日")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("学習項目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addItem()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var difficultyDescription: String {
        switch difficulty {
        case .easy: return "基礎的な内容。短時間で学習可能"
        case .medium: return "標準的な内容。適度な集中が必要"
        case .hard: return "発展的な内容。高い集中力が必要"
        case .expert: return "専門的な内容。朝の時間帯推奨"
        }
    }

    private func addItem() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        let item = StudyItem(
            title: trimmedTitle,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            category: category,
            difficulty: difficulty,
            estimatedMinutes: estimatedMinutes,
            targetDate: hasTargetDate ? targetDate : nil
        )

        modelContext.insert(item)
        dismiss()
    }
}

#Preview {
    AddStudyItemView()
        .modelContainer(for: [
            StudyItem.self,
            StudySession.self,
            StudyPlan.self,
            LearningAnalytics.self,
            UserLearningProfile.self
        ], inMemory: true)
}
