import SwiftUI

struct NewPostView: View {
    @Bindable var viewModel: FeedViewModel
    @State private var newPostViewModel = NewPostViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // MARK: - テキスト入力（複数行）

                TextEditor(text: $newPostViewModel.content)
                    .frame(height: 200)
                    .padding(8)
                    .background(Color("AsaSoftCream").opacity(0.3))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color("AsaMutedSage"), lineWidth: 1)
                    )

                // MARK: - 文字数カウント

                HStack {
                    Spacer()
                    Text("\(newPostViewModel.content.count) 文字")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                }

                // MARK: - 投稿ボタン

                Button {
                    viewModel.createPost(content: newPostViewModel.content)
                    newPostViewModel.reset()
                    dismiss()
                } label: {
                    Text("投稿する")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(newPostViewModel.canSubmit ? Color("AsaCoffeeBrown") : Color("AsaMutedSage"))
                        .cornerRadius(10)
                }
                .disabled(!newPostViewModel.canSubmit)

                Spacer()
            }
            .padding()
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaMutedSage"))
                }
            }
        }
    }
}

#Preview {
    NewPostView(viewModel: FeedViewModel(dataService: try! SocialFeedDataService.previewService()))
}
