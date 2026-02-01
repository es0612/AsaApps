import SwiftUI
import PhotosUI
import AsaFamilyTreeKit
import AsaUIKit

struct AddMemberSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyTreeViewModel.self) private var viewModel

    // MARK: - State

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var gender: Gender = .other
    @State private var birthDate: Date?
    @State private var hasBirthDate = false
    @State private var deathDate: Date?
    @State private var hasDeathDate = false
    @State private var birthPlace = ""
    @State private var notes = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImageData: Data?

    @State private var isSaving = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 基本情報
                Section("基本情報") {
                    TextField("姓", text: $lastName)
                    TextField("名", text: $firstName)

                    Picker("性別", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                }

                // プロフィール写真
                Section("プロフィール写真（任意）") {
                    HStack {
                        if let imageData = profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())

                            Button("削除") {
                                profileImageData = nil
                                selectedPhotoItem = nil
                            }
                            .foregroundStyle(.red)
                        } else {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label("写真を選択", systemImage: "photo.badge.plus")
                            }
                        }
                    }
                }

                // 生年月日
                Section("生年月日（任意）") {
                    Toggle("生年月日を設定", isOn: $hasBirthDate)

                    if hasBirthDate {
                        DatePicker(
                            "生年月日",
                            selection: Binding(
                                get: { birthDate ?? Date() },
                                set: { birthDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                    }
                }

                // 没年月日
                Section("没年月日（任意）") {
                    Toggle("没年月日を設定（故人の場合）", isOn: $hasDeathDate)

                    if hasDeathDate {
                        DatePicker(
                            "没年月日",
                            selection: Binding(
                                get: { deathDate ?? Date() },
                                set: { deathDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                    }
                }

                // 出生地
                Section("出生地（任意）") {
                    TextField("例：東京都", text: $birthPlace)
                }

                // メモ
                Section("メモ（任意）") {
                    TextField("メモを入力", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // エラーメッセージ
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("メンバーを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        saveMember()
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadPhoto(from: newItem)
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty ||
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Methods

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                profileImageData = data
            }
        }
    }

    private func saveMember() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                _ = try await viewModel.addMember(
                    firstName: firstName.trimmingCharacters(in: .whitespaces),
                    lastName: lastName.trimmingCharacters(in: .whitespaces),
                    gender: gender,
                    birthDate: hasBirthDate ? birthDate : nil,
                    deathDate: hasDeathDate ? deathDate : nil,
                    birthPlace: birthPlace.isEmpty ? nil : birthPlace,
                    notes: notes.isEmpty ? nil : notes,
                    profileImageData: profileImageData
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - Preview

#Preview {
    AddMemberSheet()
        .environment(FamilyTreeViewModel())
}
