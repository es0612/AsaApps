// AsaApps/Apps/AsaBookTracker/Views/AddBookView.swift
import SwiftUI
import AsaUIKit

/// 新しい本を追加するためのフォームビュー
struct AddBookView: View {
    @Bindable var viewModel: BookTrackerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var selectedGenre = BookGenre.fiction
    @State private var isbn = ""
    @State private var summary = ""
    @State private var coverImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // 基本情報セクション
                basicInfoSection
                
                // カバー画像セクション
                coverImageSection
                
                // 詳細情報セクション
                detailsSection
            }
            .navigationTitle("本を追加")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.mutedSage)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveBook()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $coverImage)
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var basicInfoSection: some View {
        Section(header: Text("基本情報").foregroundColor(AsaColors.coffeeBrown)) {
            // タイトル
            VStack(alignment: .leading, spacing: 8) {
                Text("タイトル *")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                
                TextField("本のタイトルを入力", text: $title)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            .padding(.vertical, 4)
            
            // 著者
            VStack(alignment: .leading, spacing: 8) {
                Text("著者 *")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                
                TextField("著者名を入力", text: $author)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            .padding(.vertical, 4)
            
            // ページ数
            VStack(alignment: .leading, spacing: 8) {
                Text("総ページ数 *")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                
                TextField("ページ数", text: $totalPages)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.numberPad)
            }
            .padding(.vertical, 4)
            
            // ジャンル
            VStack(alignment: .leading, spacing: 8) {
                Text("ジャンル")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                
                Picker("ジャンルを選択", selection: $selectedGenre) {
                    ForEach(BookGenre.allCases) { genre in
                        HStack {
                            Text(genre.icon)
                            Text(genre.rawValue)
                        }
                        .tag(genre)
                    }
                }
                .pickerStyle(.menu)
                .tint(AsaColors.coffeeBrown)
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var coverImageSection: some View {
        Section(header: Text("カバー画像").foregroundColor(AsaColors.coffeeBrown)) {
            HStack {
                // 画像プレビュー
                Group {
                    if let coverImage = coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 110)
                            .cornerRadius(8)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AsaColors.softCream)
                            .frame(width: 80, height: 110)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "photo")
                                        .font(.title2)
                                        .foregroundColor(AsaColors.mutedSage)
                                    Text("画像なし")
                                        .font(.caption)
                                        .foregroundColor(AsaColors.mutedSage)
                                }
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { showingImagePicker = true }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(coverImage == nil ? "画像を選択" : "画像を変更")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AsaColors.coffeeBrown)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AsaColors.softCream)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    if coverImage != nil {
                        Button("画像を削除") {
                            coverImage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    
                    Spacer()
                }
                .padding(.leading, 12)
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var detailsSection: some View {
        Section(header: Text("詳細情報").foregroundColor(AsaColors.coffeeBrown)) {
            // ISBN
            VStack(alignment: .leading, spacing: 8) {
                Text("ISBN（任意）")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                
                TextField("ISBN-13またはISBN-10", text: $isbn)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            .padding(.vertical, 4)
            
            // 概要
            VStack(alignment: .leading, spacing: 8) {
                Text("概要（任意）")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $summary)
                        .frame(minHeight: 100)
                        .padding(4)
                        .background(AsaColors.softCream.opacity(0.5))
                        .cornerRadius(8)
                    
                    if summary.isEmpty {
                        Text("本の概要や感想を入力...")
                            .foregroundColor(AsaColors.mutedSage.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(totalPages) != nil &&
        Int(totalPages)! > 0
    }
    
    // MARK: - Methods
    
    private func saveBook() {
        guard isFormValid else {
            showError("必須項目を正しく入力してください。")
            return
        }
        
        guard let pages = Int(totalPages), pages > 0 else {
            showError("ページ数は1以上の数字で入力してください。")
            return
        }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedISBN = isbn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : isbn.trimmingCharacters(in: .whitespacesAndNewlines)
        
        viewModel.addBook(
            title: trimmedTitle,
            author: trimmedAuthor,
            totalPages: pages,
            genre: selectedGenre.rawValue,
            isbn: trimmedISBN
        )
        
        // カバー画像がある場合は保存
        if let coverImage = coverImage,
           let imageData = coverImage.jpegData(compressionQuality: 0.8),
           let lastBook = viewModel.books.last {
            lastBook.coverImageData = imageData
            lastBook.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : summary.trimmingCharacters(in: .whitespacesAndNewlines)
            viewModel.updateBook(lastBook)
        }
        
        dismiss()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - CustomTextFieldStyle

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AsaColors.softCream.opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AsaColors.mutedSage.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - ImagePicker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    AddBookView(viewModel: BookTrackerViewModel())
}