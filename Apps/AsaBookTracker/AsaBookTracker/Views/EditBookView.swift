// AsaApps/Apps/AsaBookTracker/Views/EditBookView.swift
import SwiftUI
import AsaUIKit

/// 既存の本の情報を編集するフォームビュー
struct EditBookView: View {
    let book: Book
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
    @State private var showingDeleteAlert = false
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
                
                // レビューセクション（完読の場合）
                if book.progress?.status == .completed {
                    reviewSection
                }
                
                // 削除セクション
                deleteSection
            }
            .navigationTitle("本を編集")
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
                        saveChanges()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            loadBookData()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $coverImage)
        }
        .alert("本を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteBook()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("「\(book.title)」を削除しますか？この操作は取り消せません。")
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
    
    @State private var rating: Int = 0
    @State private var review: String = ""
    
    @ViewBuilder
    private var reviewSection: some View {
        Section(header: Text("レビュー").foregroundColor(AsaColors.coffeeBrown)) {
            // 評価
            VStack(alignment: .leading, spacing: 12) {
                Text("評価")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            rating = star
                        }) {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(star <= rating ? .orange : AsaColors.mutedSage)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    if rating > 0 {
                        Button("評価をリセット") {
                            rating = 0
                        }
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // レビューコメント
            VStack(alignment: .leading, spacing: 8) {
                Text("感想・レビュー")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $review)
                        .frame(minHeight: 120)
                        .padding(4)
                        .background(AsaColors.softCream.opacity(0.5))
                        .cornerRadius(8)
                    
                    if review.isEmpty {
                        Text("この本の感想や印象的だった部分を書いてください...")
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
    
    @ViewBuilder
    private var deleteSection: some View {
        Section {
            Button(action: { showingDeleteAlert = true }) {
                HStack {
                    Spacer()
                    Text("本を削除")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
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
    
    private func loadBookData() {
        title = book.title
        author = book.author
        totalPages = String(book.totalPages)
        selectedGenre = BookGenre.allCases.first(where: { $0.rawValue == book.genre }) ?? .fiction
        isbn = book.isbn ?? ""
        summary = book.summary ?? ""
        
        if let imageData = book.coverImageData {
            coverImage = UIImage(data: imageData)
        }
        
        // レビューデータの読み込み
        if let progress = book.progress {
            rating = progress.rating ?? 0
            review = progress.review ?? ""
        }
    }
    
    private func saveChanges() {
        guard isFormValid else {
            showError("必須項目を正しく入力してください。")
            return
        }
        
        guard let pages = Int(totalPages), pages > 0 else {
            showError("ページ数は1以上の数字で入力してください。")
            return
        }
        
        // 本の基本情報を更新
        book.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        book.author = author.trimmingCharacters(in: .whitespacesAndNewlines)
        book.totalPages = pages
        book.genre = selectedGenre.rawValue
        book.isbn = isbn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : isbn.trimmingCharacters(in: .whitespacesAndNewlines)
        book.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : summary.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // カバー画像の更新
        if let coverImage = coverImage {
            book.coverImageData = coverImage.jpegData(compressionQuality: 0.8)
        } else {
            book.coverImageData = nil
        }
        
        // レビューの更新（完読の場合）
        if book.progress?.status == .completed {
            book.progress?.rating = rating == 0 ? nil : rating
            book.progress?.review = review.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : review.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        viewModel.updateBook(book)
        dismiss()
    }
    
    private func deleteBook() {
        viewModel.deleteBook(book)
        dismiss()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Preview

#Preview {
    let sampleBook = Book(
        title: "サンプル本",
        author: "サンプル著者",
        totalPages: 300,
        genre: BookGenre.fiction.rawValue
    )
    
    return EditBookView(book: sampleBook, viewModel: BookTrackerViewModel())
}