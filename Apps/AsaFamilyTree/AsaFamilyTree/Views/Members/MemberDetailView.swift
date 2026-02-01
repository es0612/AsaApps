import SwiftUI
import PhotosUI
import AsaFamilyTreeKit
import AsaUIKit

struct MemberDetailView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyTreeViewModel.self) private var viewModel

    // MARK: - Properties

    let member: FamilyMember

    // MARK: - State

    @State private var isEditing = false
    @State private var showingRelationshipSheet = false
    @State private var showingDeleteConfirmation = false

    // MARK: - Editing State

    @State private var editFirstName = ""
    @State private var editLastName = ""
    @State private var editGender: Gender = .other
    @State private var editBirthDate: Date?
    @State private var editHasBirthDate = false
    @State private var editDeathDate: Date?
    @State private var editHasDeathDate = false
    @State private var editBirthPlace = ""
    @State private var editNotes = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var editProfileImageData: Data?

    @State private var isSaving = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // プロフィールヘッダー
                    profileHeader

                    // 基本情報
                    if isEditing {
                        editingForm
                    } else {
                        infoCards
                    }

                    // 関係者
                    if !isEditing {
                        relationshipsSection
                    }

                    // 削除ボタン
                    if isEditing {
                        deleteButton
                    }
                }
                .padding()
            }
            .navigationTitle(isEditing ? "編集" : "詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "キャンセル" : "閉じる") {
                        if isEditing {
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("保存") {
                            saveChanges()
                        }
                        .disabled(isSaving)
                    } else {
                        Button("編集") {
                            startEditing()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingRelationshipSheet) {
                RelationshipSheet(member: member)
            }
            .alert("メンバーを削除", isPresented: $showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    deleteMember()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("\(member.fullName)を削除しますか？この操作は取り消せません。")
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadPhoto(from: newItem)
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // プロフィール画像
            ZStack {
                Circle()
                    .fill(member.gender.nodeBackgroundColor)
                    .frame(width: 100, height: 100)

                if isEditing {
                    if let imageData = editProfileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: member.gender.iconName)
                            .font(.system(size: 40))
                            .foregroundStyle(member.gender.nodeBorderColor)
                    }

                    // 写真選択オーバーレイ
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Circle()
                            .fill(.black.opacity(0.4))
                            .frame(width: 100, height: 100)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                    }
                } else {
                    if let imageData = member.profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: member.gender.iconName)
                            .font(.system(size: 40))
                            .foregroundStyle(member.gender.nodeBorderColor)
                    }
                }

                Circle()
                    .strokeBorder(member.gender.nodeBorderColor, lineWidth: 3)
                    .frame(width: 100, height: 100)
            }

            // 名前
            if !isEditing {
                VStack(spacing: 4) {
                    Text(member.fullName)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        Text(member.gender.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if !member.isAlive {
                            Text("・故人")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Info Cards

    private var infoCards: some View {
        VStack(spacing: 16) {
            // 年齢・生没年
            if let age = member.age {
                InfoCardView(
                    title: member.isAlive ? "年齢" : "享年",
                    value: "\(age)歳",
                    systemImage: "calendar"
                )
            }

            if !member.lifeSpanString.isEmpty {
                InfoCardView(
                    title: "生没年",
                    value: member.lifeSpanString,
                    systemImage: "clock"
                )
            }

            if let birthPlace = member.birthPlace, !birthPlace.isEmpty {
                InfoCardView(
                    title: "出生地",
                    value: birthPlace,
                    systemImage: "mappin.and.ellipse"
                )
            }

            if let notes = member.notes, !notes.isEmpty {
                InfoCardView(
                    title: "メモ",
                    value: notes,
                    systemImage: "note.text"
                )
            }
        }
    }

    // MARK: - Editing Form

    private var editingForm: some View {
        VStack(spacing: 16) {
            GroupBox("基本情報") {
                VStack(spacing: 12) {
                    TextField("姓", text: $editLastName)
                        .textFieldStyle(.roundedBorder)

                    TextField("名", text: $editFirstName)
                        .textFieldStyle(.roundedBorder)

                    Picker("性別", selection: $editGender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            GroupBox("生年月日") {
                VStack(spacing: 12) {
                    Toggle("生年月日を設定", isOn: $editHasBirthDate)

                    if editHasBirthDate {
                        DatePicker(
                            "生年月日",
                            selection: Binding(
                                get: { editBirthDate ?? Date() },
                                set: { editBirthDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            GroupBox("没年月日") {
                VStack(spacing: 12) {
                    Toggle("没年月日を設定", isOn: $editHasDeathDate)

                    if editHasDeathDate {
                        DatePicker(
                            "没年月日",
                            selection: Binding(
                                get: { editDeathDate ?? Date() },
                                set: { editDeathDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            GroupBox("その他") {
                VStack(spacing: 12) {
                    TextField("出生地", text: $editBirthPlace)
                        .textFieldStyle(.roundedBorder)

                    TextField("メモ", text: $editNotes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                .padding(.vertical, 8)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    // MARK: - Relationships Section

    private var relationshipsSection: some View {
        VStack(spacing: 16) {
            // 両親
            if !member.parents.isEmpty {
                RelationshipGroupView(
                    title: "両親",
                    members: member.parents,
                    systemImage: "person.2.fill"
                )
            }

            // 配偶者
            if !member.spouses.isEmpty {
                RelationshipGroupView(
                    title: "配偶者",
                    members: member.spouses,
                    systemImage: "heart.fill"
                )
            }

            // 子供
            if !member.children.isEmpty {
                RelationshipGroupView(
                    title: "子供",
                    members: member.children,
                    systemImage: "figure.2.and.child.holdinghands"
                )
            }

            // 兄弟姉妹
            if !member.siblings.isEmpty {
                RelationshipGroupView(
                    title: "兄弟姉妹",
                    members: member.siblings,
                    systemImage: "person.3.fill"
                )
            }

            // 関係を追加ボタン
            Button {
                showingRelationshipSheet = true
            } label: {
                Label("関係を追加", systemImage: "person.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AsaColors.softCream)
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            Label("メンバーを削除", systemImage: "trash")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Methods

    private func startEditing() {
        editFirstName = member.firstName
        editLastName = member.lastName
        editGender = member.gender
        editBirthDate = member.birthDate
        editHasBirthDate = member.birthDate != nil
        editDeathDate = member.deathDate
        editHasDeathDate = member.deathDate != nil
        editBirthPlace = member.birthPlace ?? ""
        editNotes = member.notes ?? ""
        editProfileImageData = member.profileImageData
        isEditing = true
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                editProfileImageData = data
            }
        }
    }

    private func saveChanges() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                member.update(
                    firstName: editFirstName.trimmingCharacters(in: .whitespaces),
                    lastName: editLastName.trimmingCharacters(in: .whitespaces),
                    gender: editGender,
                    birthDate: editHasBirthDate ? editBirthDate : nil,
                    deathDate: editHasDeathDate ? editDeathDate : nil,
                    birthPlace: editBirthPlace.isEmpty ? nil : editBirthPlace,
                    notes: editNotes.isEmpty ? nil : editNotes,
                    profileImageData: editProfileImageData
                )

                try await viewModel.updateMember(member)
                isEditing = false
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func deleteMember() {
        Task {
            try? await viewModel.deleteMember(member)
            dismiss()
        }
    }
}

// MARK: - Info Card View

struct InfoCardView: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(AsaColors.coffeeBrown)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Relationship Group View

struct RelationshipGroupView: View {
    let title: String
    let members: [FamilyMember]
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(AsaColors.coffeeBrown)

            ForEach(members, id: \.id) { member in
                HStack(spacing: 12) {
                    Circle()
                        .fill(member.gender.nodeBackgroundColor)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: member.gender.iconName)
                                .font(.caption)
                                .foregroundStyle(member.gender.nodeBorderColor)
                        }

                    Text(member.fullName)
                        .font(.subheadline)

                    Spacer()

                    if !member.isAlive {
                        Text("故人")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    MemberDetailView(
        member: FamilyMember(
            firstName: "太郎",
            lastName: "山田",
            gender: .male,
            birthDate: Calendar.current.date(from: DateComponents(year: 1980, month: 5, day: 15)),
            birthPlace: "東京都",
            notes: "長男として生まれる"
        )
    )
    .environment(FamilyTreeViewModel())
}
