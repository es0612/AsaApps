import SwiftUI
import AsaUIKit

struct JoinFamilyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var familyViewModel: FamilyGroupViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var inviteCode = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 80))
                        .foregroundColor(AsaColors.mocha)
                        .padding(.top, 40)

                    VStack(spacing: 8) {
                        Text("グループに参加")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("招待コードを入力してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("招待コード")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                ForEach(0..<6, id: \.self) { index in
                                    CodeInputBox(
                                        code: $inviteCode,
                                        index: index
                                    )
                                }
                            }
                            .padding(.horizontal)

                            Text("6文字の英数字コードを入力")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }

                        if let errorMessage = familyViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        AsaButton(
                            title: "参加する",
                            action: {
                                Task {
                                    guard let user = authViewModel.currentUser else { return }
                                    await familyViewModel.joinFamilyGroup(
                                        inviteCode: inviteCode,
                                        userId: user.uid,
                                        userName: user.displayName,
                                        userEmail: user.email
                                    )
                                    if familyViewModel.familyGroup != nil {
                                        // 家族IDを更新
                                        if let groupId = familyViewModel.familyGroup?.id {
                                            await authViewModel.updateUserFamilyId(groupId)
                                        }
                                        dismiss()
                                    }
                                }
                            },
                            color: AsaColors.mocha,
                            isEnabled: !familyViewModel.isLoading && inviteCode.count == 6
                        )
                    }
                    .padding(.horizontal, 30)

                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(AsaColors.mutedSage)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("招待コードの入手方法")
                                .font(.footnote)
                                .fontWeight(.semibold)

                            Label("家族のオーナーまたは管理者から共有", systemImage: "person.crop.circle")
                            Label("グループ設定画面で確認可能", systemImage: "gearshape")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                    }

                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("グループ参加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CodeInputBox: View {
    @Binding var code: String
    let index: Int

    var character: String {
        if code.count > index {
            return String(code[code.index(code.startIndex, offsetBy: index)])
        }
        return ""
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AsaColors.mocha, lineWidth: 2)
                .frame(width: 45, height: 55)

            Text(character.uppercased())
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.darkSlate)
        }
        .onTapGesture {
            // タップで入力フィールドにフォーカス
        }
    }
}