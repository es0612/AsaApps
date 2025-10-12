//
//  AlbumsView.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import SwiftUI
import SwiftData

struct AlbumsView: View {
    var viewModel: FamilyAlbumViewModel
    @State private var showingCreateAlbum = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.albums.isEmpty {
                    EmptyStateView()
                } else {
                    AlbumGridView(albums: viewModel.filteredAlbums, viewModel: viewModel)
                }
            }
            .navigationTitle("アルバム")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateAlbum = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .searchable(text: $searchText, prompt: "アルバムを検索")
            .onChange(of: searchText) { oldValue, newValue in
                viewModel.searchText = newValue
            }
            .sheet(isPresented: $showingCreateAlbum) {
                CreateAlbumView(viewModel: viewModel)
            }
        }
    }
}

struct AlbumGridView: View {
    let albums: [Album]
    var viewModel: FamilyAlbumViewModel
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(albums) { album in
                    NavigationLink(destination: AlbumDetailView(album: album, viewModel: viewModel)) {
                        AlbumCardView(album: album, viewModel: viewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

struct AlbumCardView: View {
    let album: Album
    var viewModel: FamilyAlbumViewModel
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // サムネイル画像
            ZStack {
                Rectangle()
                    .fill(Color("AsaMutedSage").opacity(0.3))
                    .aspectRatio(4/3, contentMode: .fit)
                    .cornerRadius(12, corners: [.topLeft, .topRight])
                
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .cornerRadius(12, corners: [.topLeft, .topRight])
                } else if let recentPhoto = album.mostRecentPhoto {
                    Rectangle()
                        .fill(Color("AsaMutedSage").opacity(0.5))
                        .overlay(
                            ProgressView()
                                .tint(Color("AsaCoffeeBrown"))
                        )
                        .task {
                            thumbnailImage = await viewModel.loadImage(for: recentPhoto, size: CGSize(width: 200, height: 150))
                        }
                } else {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            // アルバム情報
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                    .lineLimit(1)
                
                Text("\(album.photoCount)枚の写真")
                    .font(.caption)
                    .foregroundColor(Color("AsaMocha"))
                
                if let description = album.albumDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(Color("AsaMutedSage"))
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color("AsaDarkSlate").opacity(0.1), radius: 4)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color("AsaCoffeeBrown"))
            
            Text("アルバムを読み込んでいます...")
                .font(.body)
                .foregroundColor(Color("AsaMocha"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(Color("AsaMutedSage"))
            
            VStack(spacing: 8) {
                Text("アルバムがありません")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("右上の「+」ボタンから\n最初のアルバムを作成しましょう")
                    .font(.body)
                    .foregroundColor(Color("AsaMocha"))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

struct CreateAlbumView: View {
    var viewModel: FamilyAlbumViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var tags = ""
    
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
                
                Section {
                    Button("アルバムを作成") {
                        Task {
                            let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                            await viewModel.createAlbum(name: name, description: description.isEmpty ? nil : description, tags: tagArray)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? Color("AsaMutedSage") : Color("AsaCoffeeBrown"))
                }
            }
            .navigationTitle("新しいアルバム")
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

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    AlbumsView(viewModel: FamilyAlbumViewModel())
        .modelContainer(for: [Album.self, Photo.self, Comment.self, FamilyMember.self])
}
