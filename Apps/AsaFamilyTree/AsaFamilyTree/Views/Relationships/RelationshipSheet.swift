import SwiftUI
import AsaFamilyTreeKit
import AsaUIKit

struct RelationshipSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyTreeViewModel.self) private var viewModel

    // MARK: - Properties

    let member: FamilyMember

    // MARK: - State

    @State private var selectedRelationType: RelationType = .parent
    @State private var selectedMember: FamilyMember?
    @State private var marriageDate: Date?
    @State private var hasMarriageDate = false

    @State private var isSaving = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 関係タイプ選択
                Section("関係の種類") {
                    Picker("関係", selection: $selectedRelationType) {
                        ForEach(RelationType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 説明
                Section {
                    Text(relationTypeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // メンバー選択
                Section("メンバーを選択") {
                    if availableMembers.isEmpty {
                        Text("選択可能なメンバーがいません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availableMembers, id: \.id) { availableMember in
                            Button {
                                selectedMember = availableMember
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(availableMember.gender.nodeBackgroundColor)
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            Image(systemName: availableMember.gender.iconName)
                                                .font(.caption)
                                                .foregroundStyle(availableMember.gender.nodeBorderColor)
                                        }

                                    Text(availableMember.fullName)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if selectedMember?.id == availableMember.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AsaColors.coffeeBrown)
                                    }
                                }
                            }
                        }
                    }
                }

                // 配偶者の場合は結婚日を入力
                if selectedRelationType == .spouse && selectedMember != nil {
                    Section("結婚情報（任意）") {
                        Toggle("結婚日を設定", isOn: $hasMarriageDate)

                        if hasMarriageDate {
                            DatePicker(
                                "結婚日",
                                selection: Binding(
                                    get: { marriageDate ?? Date() },
                                    set: { marriageDate = $0 }
                                ),
                                displayedComponents: .date
                            )
                        }
                    }
                }

                // エラーメッセージ
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("関係を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        saveRelationship()
                    }
                    .disabled(selectedMember == nil || isSaving)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var relationTypeDescription: String {
        switch selectedRelationType {
        case .parent:
            return "\(member.fullName)の親を選択します。"
        case .child:
            return "\(member.fullName)の子供を選択します。"
        case .spouse:
            return "\(member.fullName)の配偶者を選択します。"
        }
    }

    private var availableMembers: [FamilyMember] {
        guard let tree = viewModel.currentTree else { return [] }

        return tree.members.filter { otherMember in
            // 自分自身は除外
            guard otherMember.id != member.id else { return false }

            switch selectedRelationType {
            case .parent:
                // すでに親に設定されているメンバーは除外
                return !member.parents.contains { $0.id == otherMember.id }

            case .child:
                // すでに子供に設定されているメンバーは除外
                return !member.children.contains { $0.id == otherMember.id }

            case .spouse:
                // すでに配偶者に設定されているメンバーは除外
                return !member.spouses.contains { $0.id == otherMember.id }
            }
        }
    }

    // MARK: - Methods

    private func saveRelationship() {
        guard let selected = selectedMember else { return }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                switch selectedRelationType {
                case .parent:
                    try await viewModel.setParentChild(parent: selected, child: member)

                case .child:
                    try await viewModel.setParentChild(parent: member, child: selected)

                case .spouse:
                    _ = try await viewModel.createMarriage(
                        partner1: member,
                        partner2: selected,
                        marriageDate: hasMarriageDate ? marriageDate : nil
                    )
                }

                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - Relation Type

enum RelationType: String, CaseIterable {
    case parent
    case child
    case spouse

    var displayName: String {
        switch self {
        case .parent: return "親"
        case .child: return "子"
        case .spouse: return "配偶者"
        }
    }
}

// MARK: - Preview

#Preview {
    RelationshipSheet(
        member: FamilyMember(
            firstName: "太郎",
            lastName: "山田",
            gender: .male
        )
    )
    .environment(FamilyTreeViewModel())
}
