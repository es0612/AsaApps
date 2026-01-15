import SwiftUI
import PhotosUI

// MARK: - Firebase New Post View

struct FirebaseNewPostView: View {
    // MARK: - Properties

    @Bindable var viewModel: FirebaseFeedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?

    @FocusState private var isTextEditorFocused: Bool

    private let maxCharacters = 500

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AsaSoftCream")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ユーザー情報
                        userHeader

                        // テキスト入力
                        textEditor

                        // 画像選択
                        imageSection

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    postButton
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    await loadImage(from: newItem)
                }
            }
            .onAppear {
                isTextEditorFocused = true
            }
        }
    }

    // MARK: - User Header

    private var userHeader: some View {
        HStack(spacing: 12) {
            // アバター
            Circle()
                .fill(Color("AsaCoffeeBrown").opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(String(viewModel.currentUserName.prefix(1)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("AsaCoffeeBrown"))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentUserName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AsaDarkSlate"))

                Text("公開投稿")
                    .font(.caption)
                    .foregroundStyle(Color("AsaMutedSage"))
            }

            Spacer()
        }
    }

    // MARK: - Text Editor

    private var textEditor: some View {
        VStack(alignment: .trailing, spacing: 8) {
            TextEditor(text: $content)
                .frame(minHeight: 150)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("AsaMutedSage").opacity(0.3), lineWidth: 1)
                )
                .focused($isTextEditorFocused)
                .overlay(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("今日の朝活は何をしましたか？")
                            .foregroundStyle(Color("AsaMutedSage"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }

            // 文字数カウント
            Text("\(content.count)/\(maxCharacters)")
                .font(.caption)
                .foregroundStyle(content.count > maxCharacters ? .red : Color("AsaMutedSage"))
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 選択された画像
            if let image = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 200)
                        .clipped()
                        .cornerRadius(12)

                    // 削除ボタン
                    Button {
                        withAnimation {
                            selectedItem = nil
                            selectedImage = nil
                            selectedImageData = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            }

            // 画像選択ボタン
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text(selectedImage == nil ? "画像を追加" : "画像を変更")
                }
                .font(.subheadline)
                .foregroundStyle(Color("AsaCoffeeBrown"))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color("AsaCoffeeBrown").opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Post Button

    private var postButton: some View {
        Button {
            Task {
                await viewModel.createPost(content: content, imageData: selectedImageData)
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .tint(Color("AsaCoffeeBrown"))
            } else {
                Text("投稿")
                    .fontWeight(.semibold)
            }
        }
        .disabled(!isValidPost || viewModel.isLoading)
    }

    // MARK: - Computed Properties

    private var isValidPost: Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedContent.isEmpty && content.count <= maxCharacters
    }

    // MARK: - Methods

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedImageData = data
                selectedImage = UIImage(data: data)
            }
        } catch {
            print("Failed to load image: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    let authService = FirebaseAuthService()
    let dataService = FirestoreSocialFeedDataService()
    let authVM = AuthViewModel(authService: authService)
    let feedVM = FirebaseFeedViewModel(dataService: dataService, authViewModel: authVM)

    FirebaseNewPostView(viewModel: feedVM)
}
