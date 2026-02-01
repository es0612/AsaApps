//
//  EditDiaryView.swift
//  AsaVRDiary
//
//  日記編集画面
//

import SwiftUI

/// 日記編集画面
struct EditDiaryView: View {
    let entry: DiaryEntry
    @Bindable var viewModel: DiaryViewModel
    @State private var editState: EditingDiaryState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field {
        case title, content
    }

    init(entry: DiaryEntry, viewModel: DiaryViewModel) {
        self.entry = entry
        self.viewModel = viewModel
        self._editState = State(initialValue: EditingDiaryState(from: entry))
    }

    var body: some View {
        NavigationStack {
            Form {
                // 基本情報
                Section("基本情報") {
                    TextField("タイトル", text: $editState.title)
                        .focused($focusedField, equals: .title)

                    DatePicker("日付", selection: $editState.date, displayedComponents: .date)
                }

                // 本文
                Section("内容") {
                    TextEditor(text: $editState.content)
                        .focused($focusedField, equals: .content)
                        .frame(minHeight: 150)
                }

                // カテゴリ
                Section("カテゴリ") {
                    CategoryPicker(selectedCategory: $editState.category)
                }

                // 気分
                Section("今日の気分") {
                    MoodPicker(
                        selectedMood: $editState.mood,
                        intensity: $editState.moodIntensity
                    )
                }

                // VR位置（設定されている場合）
                if entry.hasCustomVRPosition {
                    Section("VR位置") {
                        Button("VR位置をリセット") {
                            entry.resetVRPosition()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("日記を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateDiary()
                    }
                    .disabled(!editState.isValid)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("完了") {
                            focusedField = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Methods

    private func updateDiary() {
        entry.title = editState.title.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.content = editState.content.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.date = editState.date
        entry.category = editState.category
        entry.mood = editState.mood
        entry.moodIntensity = editState.moodIntensity

        viewModel.updateEntry(entry)
        dismiss()
    }
}

#Preview {
    EditDiaryView(
        entry: DiaryEntry(
            title: "テスト日記",
            content: "これはテストの内容です。",
            category: .daily,
            mood: .happy,
            moodIntensity: 4
        ),
        viewModel: DiaryViewModel()
    )
}
