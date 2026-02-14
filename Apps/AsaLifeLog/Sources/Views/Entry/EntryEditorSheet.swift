import SwiftUI
import AsaLifeLogKit

// MARK: - EntryEditorSheet

/// エントリー編集シート
struct EntryEditorSheet: View {
    @Bindable var viewModel: EntryEditorViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                // タイトル・内容
                Section("基本情報") {
                    TextField("タイトル", text: $viewModel.title)
                    TextField("メモ（任意）", text: $viewModel.content, axis: .vertical)
                        .lineLimit(3...6)
                }

                // 気分選択
                Section("気分") {
                    MoodSelector(selectedMood: $viewModel.moodScore)
                }

                // タグ
                Section("タグ") {
                    TagInput(tags: $viewModel.tags)
                }

                // 位置情報
                Section("場所") {
                    LocationPicker(
                        locationName: $viewModel.locationName,
                        onRequestLocation: {
                            Task { await viewModel.setCurrentLocation() }
                        }
                    )
                }

                // 写真
                Section("写真") {
                    PhotoAttachment(identifiers: $viewModel.photoIdentifiers)
                }
            }
            .navigationTitle("新しい記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            let success = await viewModel.saveEntry()
                            if success {
                                isPresented = false
                            }
                        }
                    }
                    .disabled(viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
