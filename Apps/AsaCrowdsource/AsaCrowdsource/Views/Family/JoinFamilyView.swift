//
//  JoinFamilyView.swift
//  AsaCrowdsource
//
//  グループ参加画面
//

import SwiftUI
import AsaUIKit

struct JoinFamilyView: View {
    // MARK: - Properties

    @EnvironmentObject private var familyViewModel: FamilyGroupViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var inviteCode = ""
    @State private var displayName = ""

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).count == 6 &&
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                    // 参加ボタン
                    joinButton
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
            .onAppear {
                // 認証ユーザーの表示名をデフォルトに設定
                if let user = authViewModel.currentUser {
                    displayName = user.displayName
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(Color(AsaColors.coffeeBrown))

            Text("グループに参加")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(AsaColors.darkSlate))

            Text("招待コードを入力してグループに参加しましょう")
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.mutedSage))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            // 招待コード
            VStack(alignment: .leading, spacing: 8) {
                Text("招待コード *")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(AsaColors.darkSlate))

                TextField("6文字のコード", text: $inviteCode)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onChange(of: inviteCode) { _, newValue in
                        // 6文字に制限
                        if newValue.count > 6 {
                            inviteCode = String(newValue.prefix(6))
                        }
                        // 大文字に変換
                        inviteCode = inviteCode.uppercased()
                    }

                Text("グループのオーナーから招待コードを受け取ってください")
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.mutedSage))
            }

            // 表示名
            VStack(alignment: .leading, spacing: 8) {
                Text("表示名 *")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(AsaColors.darkSlate))

                TextField("グループ内で表示される名前", text: $displayName)
                    .textFieldStyle(RoundedTextFieldStyle())

                Text("他のメンバーに表示される名前です")
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.mutedSage))
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

    private var joinButton: some View {
        Button {
            Task {
                await familyViewModel.joinGroup(
                    inviteCode: inviteCode,
                    displayName: displayName
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
                    Image(systemName: "person.badge.plus")
                    Text("グループに参加")
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
    JoinFamilyView()
        .environmentObject(FamilyGroupViewModel())
        .environmentObject(AuthViewModel())
}
