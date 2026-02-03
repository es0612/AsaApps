//
//  CreateFamilyView.swift
//  AsaCrowdsource
//
//  グループ作成画面
//

import SwiftUI
import AsaUIKit

struct CreateFamilyView: View {
    // MARK: - Properties

    @EnvironmentObject private var familyViewModel: FamilyGroupViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var groupName = ""
    @State private var groupDescription = ""

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    headerSection

                    // 入力フォーム
                    formSection

                    // エラーメッセージ
                    if let error = familyViewModel.errorMessage {
                        errorMessageView(error)
                    }

                    // 作成ボタン
                    createButton
                }
                .padding(24)
            }
            .background(Color(AsaColors.softCream).opacity(0.3))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color(AsaColors.coffeeBrown))
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(AsaColors.coffeeBrown))

            Text("グループを作成")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(AsaColors.darkSlate))

            Text("家族やグループでアイデアを共有しましょう")
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.mutedSage))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            // グループ名
            VStack(alignment: .leading, spacing: 8) {
                Text("グループ名 *")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(AsaColors.darkSlate))

                TextField("例：田中家", text: $groupName)
                    .textFieldStyle(RoundedTextFieldStyle())
            }

            // 説明
            VStack(alignment: .leading, spacing: 8) {
                Text("説明（任意）")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(AsaColors.darkSlate))

                TextField("グループの説明を入力", text: $groupDescription, axis: .vertical)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
    }

    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    private var createButton: some View {
        Button {
            Task {
                await familyViewModel.createGroup(
                    name: groupName,
                    description: groupDescription
                )
                if familyViewModel.hasGroup {
                    dismiss()
                }
            }
        } label: {
            HStack {
                if familyViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "plus.circle.fill")
                    Text("グループを作成")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(AsaColors.coffeeBrown))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || familyViewModel.isLoading)
        .opacity(isFormValid ? 1.0 : 0.6)
    }
}

// MARK: - Preview

#Preview {
    CreateFamilyView()
        .environmentObject(FamilyGroupViewModel())
}
