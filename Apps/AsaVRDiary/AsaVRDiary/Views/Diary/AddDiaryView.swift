//
//  AddDiaryView.swift
//  AsaVRDiary
//
//  日記追加画面
//

import SwiftUI

/// 日記追加画面
struct AddDiaryView: View {
    @Bindable var viewModel: DiaryViewModel
    @State private var editState = EditingDiaryState()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field {
        case title, content
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
            }
            .navigationTitle("新しい日記")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveDiary()
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
            .onAppear {
                focusedField = .title
            }
        }
    }

    // MARK: - Methods

    private func saveDiary() {
        viewModel.createEntry(
            title: editState.title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: editState.content.trimmingCharacters(in: .whitespacesAndNewlines),
            date: editState.date,
            category: editState.category,
            mood: editState.mood,
            moodIntensity: editState.moodIntensity
        )
        dismiss()
    }
}

#Preview {
    AddDiaryView(viewModel: DiaryViewModel())
}
