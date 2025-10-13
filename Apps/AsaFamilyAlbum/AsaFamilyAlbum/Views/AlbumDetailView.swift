//
//  AlbumDetailView.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import SwiftUI
import SwiftData

struct AlbumDetailView: View {
    let album: Album
    var viewModel: FamilyAlbumViewModel
    @State private var showingEditAlbum = false
    @State private var showingDeleteAlert = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: Photo?
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // アルバムヘッダー
                AlbumHeaderView(album: album, viewModel: viewModel)
                
                // 写真グリッド
                if album.photos.isEmpty {
                    EmptyAlbumView(showingPhotoPicker: $showingPhotoPicker)
                } else {
                    PhotoGridSection(album: album, viewModel: viewModel, selectedPhoto: $selectedPhoto)
                }
            }
        }
        .background(Color("AsaSoftCream").opacity(0.3))
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingPhotoPicker = true
                } label: {
                    Image(systemName: "photo.badge.plus")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                Button {
                    showingEditAlbum = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                Menu {
                    Button("アルバムを編集", systemImage: "pencil") {
                        showingEditAlbum = true
                    }
                    
                    Button("エクスポート", systemImage: "square.and.arrow.up") {
                        Task {
                            _ = await viewModel.exportAlbum(album)
                        }
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
        .sheet(isPresented: $showingEditAlbum) {
            EditAlbumView(album: album, viewModel: viewModel)
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo, viewModel: viewModel)
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(album: album, viewModel: viewModel)
        }
        .alert("アルバムを削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                Task {
                    await viewModel.deleteAlbum(album)
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("このアルバムとすべての写真を削除しますか？この操作は元に戻せません。")
        }
    }
}

struct AlbumHeaderView: View {
    let album: Album
    var viewModel: FamilyAlbumViewModel
    @State private var featuredImage: UIImage?
    
    var body: some View {
        VStack(spacing: 16) {
            // フィーチャー画像
            ZStack {
                Rectangle()
                    .fill(Color("AsaMutedSage").opacity(0.3))
                    .frame(height: 200)
                
                if let image = featuredImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                } else if let recentPhoto = album.recentPhotos.first {
                    Rectangle()
                        .fill(Color("AsaMutedSage").opacity(0.5))
                        .overlay(
                            ProgressView()
                                .tint(Color("AsaCoffeeBrown"))
                        )
                        .task {
                            featuredImage = await viewModel.loadImage(for: recentPhoto, size: CGSize(width: 400, height: 200))
                        }
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            // アルバム情報
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    Text(album.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaDarkSlate"))
                        .multilineTextAlignment(.center)
                    
                    if let description = album.albumDescription, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(Color("AsaMocha"))
                            .multilineTextAlignment(.center)
                    }
                }
                
                // 統計情報
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(album.photoCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text("写真")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    VStack(spacing: 4) {
                        Text(album.dateRange)
                            .font(.headline)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text("期間")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }
                
                // タグ
                if !album.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(album.tags, id: \.self) { tag in
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
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
}

struct PhotoGridSection: View {
    let album: Album
    var viewModel: FamilyAlbumViewModel
    @Binding var selectedPhoto: Photo?
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(album.photos) { photo in
                Button {
                    selectedPhoto = photo
                } label: {
                    PhotoThumbnailView(photo: photo, viewModel: viewModel)
                        .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 1)
    }
}

struct EmptyAlbumView: View {
    @Binding var showingPhotoPicker: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(Color("AsaMutedSage"))
            
            VStack(spacing: 8) {
                Text("このアルバムは空です")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("写真ライブラリから写真を\n追加してください")
                    .font(.body)
                    .foregroundColor(Color("AsaMocha"))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingPhotoPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.headline)
                    Text("写真を追加")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color("AsaCoffeeBrown"))
                .cornerRadius(10)
                .shadow(color: Color("AsaDarkSlate").opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.bottom, 120)
    }
}

struct EditAlbumView: View {
    let album: Album
    var viewModel: FamilyAlbumViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var description: String
    @State private var tags: String
    
    init(album: Album, viewModel: FamilyAlbumViewModel) {
        self.album = album
        self.viewModel = viewModel
        self._name = State(initialValue: album.name)
        self._description = State(initialValue: album.albumDescription ?? "")
        self._tags = State(initialValue: album.tags.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("アルバム情報").foregroundColor(Color("AsaCoffeeBrown"))) {
                    TextField("アルバム名", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("説明（オプション）", text: $description, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                    
                    TextField("タグ（カンマ区切り）", text: $tags)
                        .textInputAutocapitalization(.words)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("統計")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("写真数")
                        Spacer()
                        Text("\(album.photoCount)枚")
                            .foregroundColor(Color("AsaMocha"))
                    }
                    
                    HStack {
                        Text("作成日")
                        Spacer()
                        Text(album.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(Color("AsaMocha"))
                    }
                    
                        HStack {
                            Text("最終更新")
                            Spacer()
                            Text(album.updatedAt.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(Color("AsaMocha"))
                        }
                    }
                    .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    Button("変更を保存") {
                        Task {
                            await viewModel.updateAlbum(
                                album,
                                name: name,
                                description: description.isEmpty ? nil : description
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || name == album.name && description == (album.albumDescription ?? "") && tags == album.tags.joined(separator: ", "))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .navigationTitle("アルバムを編集")
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

#Preview {
    let album = Album.sampleAlbums[0]
    AlbumDetailView(album: album, viewModel: FamilyAlbumViewModel())
        .modelContainer(for: [Album.self, Photo.self, Comment.self, FamilyMember.self])
}
