import SwiftUI

struct UserNameSettingView: View {
    @Bindable var viewModel: FeedViewModel
    @State private var tempUserName: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // MARK: - アイコン

                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(Color("AsaCoffeeBrown"))

                // MARK: - タイトル

                Text("ユーザー名を設定")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaDarkSlate"))

                // MARK: - 説明

                Text("投稿やいいねに表示される名前です")
                    .font(.body)
                    .foregroundColor(Color("AsaMutedSage"))

                // MARK: - テキストフィールド

                TextField("ユーザー名", text: $tempUserName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // MARK: - 保存ボタン

                Button {
                    viewModel.setUserName(tempUserName)
                    dismiss()
                } label: {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color("AsaCoffeeBrown") : Color("AsaMutedSage"))
                        .cornerRadius(10)
                }
                .disabled(!canSave)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.hasUserName {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            dismiss()
                        }
                        .foregroundColor(Color("AsaMutedSage"))
                    }
                }
            }
            .interactiveDismissDisabled(!viewModel.hasUserName)
            .onAppear {
                tempUserName = viewModel.currentUserName
            }
        }
    }

    // MARK: - Computed Properties

    private var canSave: Bool {
        !tempUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    UserNameSettingView(viewModel: FeedViewModel(dataService: try! SocialFeedDataService.previewService()))
}
