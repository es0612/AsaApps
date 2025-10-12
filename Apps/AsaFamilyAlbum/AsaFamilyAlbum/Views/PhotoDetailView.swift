//
//  PhotoDetailView.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import SwiftUI
import SwiftData

struct PhotoDetailView: View {
    let photo: Photo
    var viewModel: FamilyAlbumViewModel
    @State private var fullImage: UIImage?
    @State private var showingCommentSheet = false
    @State private var showingTagSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 写真表示
                PhotoImageView(photo: photo, viewModel: viewModel, fullImage: $fullImage)
                
                // 写真情報
                PhotoInfoSection(
                    photo: photo,
                    viewModel: viewModel,
                    showingCommentSheet: $showingCommentSheet,
                    showingTagSheet: $showingTagSheet
                )
            }
        }
        .background(Color("AsaSoftCream").opacity(0.3))
        .navigationTitle("写真詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.togglePhotoFavorite(photo)
                    }
                } label: {
                    Image(systemName: photo.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(photo.isFavorite ? .red : Color("AsaCoffeeBrown"))
                }
                
                Menu {
                    Button("編集", systemImage: "pencil") {
                        showingEditSheet = true
                    }
                    
                    Button("コメントを追加", systemImage: "bubble.left") {
                        showingCommentSheet = true
                    }
                    
                    Button("家族をタグ付け", systemImage: "person.crop.circle.badge.plus") {
                        showingTagSheet = true
                    }
                    
                    Button("共有", systemImage: "square.and.arrow.up") {
                        showingShareSheet = true
                    }
                    
                    Divider()
                    
                    Button("削除", systemImage: "trash", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
        .sheet(isPresented: $showingCommentSheet) {
            AddCommentView(photo: photo, viewModel: viewModel)
        }
        .sheet(isPresented: $showingTagSheet) {
            TagFamilyMembersView(photo: photo, viewModel: viewModel)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPhotoView(photo: photo, viewModel: viewModel)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = fullImage {
                ShareSheet(items: [image])
            }
        }
        .alert("写真を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                Task {
                    await viewModel.deletePhoto(photo)
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この写真を削除しますか？この操作は元に戻せません。")
        }
    }
}

struct PhotoImageView: View {
    let photo: Photo
    var viewModel: FamilyAlbumViewModel
    @Binding var fullImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color("AsaMutedSage").opacity(0.3))
                .aspectRatio(4/3, contentMode: .fit)
            
            if let image = fullImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Color("AsaCoffeeBrown"))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundColor(Color("AsaMutedSage"))
            }
        }
        .task {
            guard fullImage == nil else { return }
            
            let loadedImage = await viewModel.loadFullSizeImage(for: photo)
            await MainActor.run {
                self.fullImage = loadedImage
                self.isLoading = false
            }
        }
    }
}

struct PhotoInfoSection: View {
    let photo: Photo
    var viewModel: FamilyAlbumViewModel
    @Binding var showingCommentSheet: Bool
    @Binding var showingTagSheet: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // 基本情報
            VStack(alignment: .leading, spacing: 16) {
                if let title = photo.title, !title.isEmpty {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                }
                
                if let description = photo.userDescription, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundColor(Color("AsaMocha"))
                }
                
                // 日時と場所
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        Text(photo.formattedDate)
                            .foregroundColor(Color("AsaDarkSlate"))
                    }
                    
                    if let location = photo.location, !location.isEmpty {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Text(location)
                                .foregroundColor(Color("AsaDarkSlate"))
                        }
                    }
                }
                .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // EXIF情報
            if photo.hasExifData {
                PhotoExifView(photo: photo)
            }
            
            // タグ付きメンバー
            if !photo.taggedFamilyMembers.isEmpty {
                PhotoTaggedMembersView(photo: photo, viewModel: viewModel)
            }
            
            // タグ
            if !photo.tags.isEmpty {
                PhotoTagsView(photo: photo)
            }
            
            // アクションボタン
            PhotoActionsView(
                photo: photo,
                showingCommentSheet: $showingCommentSheet,
                showingTagSheet: $showingTagSheet
            )
            
            // コメント
            if !photo.comments.isEmpty {
                PhotoCommentsView(photo: photo, viewModel: viewModel)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
    }
}

struct PhotoExifView: View {
    let photo: Photo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("撮影情報")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
                .padding(.horizontal)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                alignment: .leading,
                spacing: 12
            ) {
                if let make = photo.cameraMake, let model = photo.cameraModel {
                    ExifInfoRow(label: "カメラ", value: "\(make) \(model)")
                }
                
                if let aperture = photo.aperture {
                    ExifInfoRow(label: "絞り", value: "F/\(aperture)")
                }
                
                if let shutterSpeed = photo.shutterSpeed {
                    ExifInfoRow(label: "シャッター", value: shutterSpeed)
                }
                
                if let iso = photo.iso {
                    ExifInfoRow(label: "ISO", value: iso)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ExifInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color("AsaDarkSlate"))
        }
    }
}

struct PhotoTaggedMembersView: View {
    let photo: Photo
    var viewModel: FamilyAlbumViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("タグ付きメンバー")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(photo.taggedFamilyMembers) { member in
                        NavigationLink(destination: FamilyMemberDetailView(member: member, viewModel: viewModel)) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color(member.color).opacity(0.8))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: member.relationshipIcon)
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                
                                Text(member.displayName)
                                    .font(.caption)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct PhotoTagsView: View {
    let photo: Photo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("タグ")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(photo.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AsaCoffeeBrown").opacity(0.1))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct PhotoActionsView: View {
    let photo: Photo
    @Binding var showingCommentSheet: Bool
    @Binding var showingTagSheet: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                showingCommentSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                    Text("コメント")
                }
                .font(.subheadline)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color("AsaCoffeeBrown").opacity(0.1))
                .cornerRadius(20)
            }
            
            Button {
                showingTagSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("タグ付け")
                }
                .font(.subheadline)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color("AsaCoffeeBrown").opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding(.horizontal)
    }
}

struct PhotoCommentsView: View {
    let photo: Photo
    var viewModel: FamilyAlbumViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("コメント")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
                .padding(.horizontal)
            
            ForEach(photo.comments.sorted { $0.createdAt < $1.createdAt }) { comment in
                CommentRow(comment: comment)
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.author)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Spacer()
                
                Text(comment.timeAgo)
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
                
                if comment.isEdited {
                    Text("(編集済み)")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            Text(comment.displayText)
                .font(.body)
                .foregroundColor(Color("AsaMocha"))
        }
        .padding(12)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Supplementary Views

struct AddCommentView: View {
    let photo: Photo
    var viewModel: FamilyAlbumViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var commentText = ""
    @State private var authorName = "家族"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("著者名", text: $authorName)
                    .textFieldStyle(.roundedBorder)
                
                TextEditor(text: $commentText)
                    .frame(minHeight: 120)
                    .background(Color("AsaSoftCream").opacity(0.3))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("コメントを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaMocha"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        Task {
                            await viewModel.addCommentToPhoto(photo, text: commentText, author: authorName)
                            dismiss()
                        }
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
    }
}

struct TagFamilyMembersView: View {
    let photo: Photo
    var viewModel: FamilyAlbumViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.familyMembers) { member in
                    Button {
                        Task {
                            await viewModel.tagFamilyMemberInPhoto(photo, member: member)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(member.color).opacity(0.8))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: member.relationshipIcon)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.displayName)
                                    .font(.headline)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                
                                Text(member.relationship)
                                    .font(.caption)
                                    .foregroundColor(Color("AsaMocha"))
                            }
                            
                            Spacer()
                            
                            if photo.taggedFamilyMembers.contains(member) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("家族をタグ付け")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
    }
}

struct EditPhotoView: View {
    let photo: Photo
    var viewModel: FamilyAlbumViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var tags: String
    
    init(photo: Photo, viewModel: FamilyAlbumViewModel) {
        self.photo = photo
        self.viewModel = viewModel
        self._title = State(initialValue: photo.title ?? "")
        self._description = State(initialValue: photo.userDescription ?? "")
        self._tags = State(initialValue: photo.tags.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("写真情報").foregroundColor(Color("AsaCoffeeBrown"))) {
                    TextField("タイトル", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    TextField("説明", text: $description, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                    
                    TextField("タグ（カンマ区切り）", text: $tags)
                        .textInputAutocapitalization(.words)
                }
                
                Section {
                    Button("変更を保存") {
                        // 保存処理（実装省略）
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .navigationTitle("写真を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaMocha"))
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let samplePhoto = Photo(
        assetID: "sample-asset-id",
        title: "サンプル写真",
        userDescription: "これはサンプルの写真です。",
        tags: ["家族", "旅行"]
    )
    PhotoDetailView(photo: samplePhoto, viewModel: FamilyAlbumViewModel())
        .modelContainer(for: [Album.self, Photo.self, Comment.self, FamilyMember.self])
}
