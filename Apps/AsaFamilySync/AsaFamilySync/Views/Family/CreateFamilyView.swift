import SwiftUI
import AsaUIKit

struct CreateFamilyView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var familyViewModel = FamilyGroupViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var familyName = ""
    @State private var familyDescription = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    Image(systemName: "house.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AsaColors.coffeeBrown)
                        .padding(.top, 40)

                    VStack(spacing: 8) {
                        Text("新しい家族グループ")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("家族みんなで予定を共有しましょう")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("グループ名")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("例: 田中家", text: $familyName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("説明（任意）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("グループの説明", text: $familyDescription, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...5)
                        }

                        if let errorMessage = familyViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        AsaButton(
                            title: "グループを作成",
                            action: {
                                Task {
                                    await familyViewModel.createFamilyGroup(
                                        name: familyName,
                                        description: familyDescription.isEmpty ? nil : familyDescription
                                    )
                                    if familyViewModel.familyGroup != nil {
                                        dismiss()
                                    }
                                }
                            },
                            color: AsaColors.coffeeBrown,
                            isLoading: familyViewModel.isLoading
                        )
                        .disabled(familyName.isEmpty)
                    }
                    .padding(.horizontal, 30)

                    VStack(spacing: 16) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(AsaColors.mutedSage)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("最大10名まで参加可能", systemImage: "person.3")
                            Label("招待コードで家族を招待", systemImage: "envelope")
                            Label("管理者権限の設定が可能", systemImage: "shield")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                    }

                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("グループ作成")
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