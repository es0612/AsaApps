import SwiftUI
import PhotosUI
import AsaUIKit
import AsaCommunityKit

/// 投稿作成シート
struct CreatePostSheet: View {
    @Bindable var viewModel: PostFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: PostCategory = .general
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Category
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(PostCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                }

                // MARK: - Content
                Section("投稿内容") {
                    TextField("タイトル", text: $title)
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }

                // MARK: - Photo
                Section("写真") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(
                            imageData == nil ? "写真を追加" : "写真を変更",
                            systemImage: "photo.badge.plus"
                        )
                    }
                    if imageData != nil {
                        HStack {
                            Image(systemName: "photo.fill")
                                .foregroundStyle(AsaColors.coffeeBrown)
                            Text("写真が選択されています")
                                .font(.caption)
                            Spacer()
                            Button("削除") {
                                imageData = nil
                                selectedPhoto = nil
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("新しい投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("投稿") {
                        submitPost()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
            .alert("確認", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func submitPost() {
        viewModel.createPost(
            title: title,
            content: content,
            category: selectedCategory,
            imageData: imageData
        )
        dismiss()
    }
}
