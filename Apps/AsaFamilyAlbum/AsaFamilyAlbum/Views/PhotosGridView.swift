//
//  PhotosGridView.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import SwiftUI
import SwiftData

struct PhotosGridView: View {
    var viewModel: FamilyAlbumViewModel
    @State private var showingFilterSheet = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.filteredPhotos.isEmpty {
                    EmptyPhotosView()
                } else {
                    PhotoGrid(photos: viewModel.filteredPhotos, viewModel: viewModel)
                }
            }
            .navigationTitle("すべての写真")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(viewModel: viewModel)
            }
        }
    }
}

struct PhotoGrid: View {
    let photos: [Photo]
    var viewModel: FamilyAlbumViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(photos) { photo in
                    NavigationLink(destination: PhotoDetailView(photo: photo, viewModel: viewModel)) {
                        PhotoThumbnailView(photo: photo, viewModel: viewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 1)
        }
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

struct PhotoThumbnailView: View {
    let photo: Photo
    var viewModel: FamilyAlbumViewModel
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color("AsaMutedSage").opacity(0.3))
                .aspectRatio(1, contentMode: .fit)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Color("AsaCoffeeBrown"))
            } else {
                Image(systemName: "photo")
                    .font(.title)
                    .foregroundColor(Color("AsaMutedSage"))
            }
            
            // お気に入りインジケーター
            if photo.isFavorite {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(4)
                    }
                    Spacer()
                }
            }
            
            // タグ付きメンバーインジケーター
            if !photo.taggedFamilyMembers.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .font(.caption2)
                        Spacer()
                    }
                    .padding(4)
                }
            }
        }
        .task {
            guard image == nil else { return }
            
            let loadedImage = await viewModel.loadImage(for: photo, size: CGSize(width: 150, height: 150))
            await MainActor.run {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}

struct EmptyPhotosView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundColor(Color("AsaMutedSage"))
            
            VStack(spacing: 8) {
                Text("写真がありません")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("写真ライブラリから読み込むか\nアルバムを作成してください")
                    .font(.body)
                    .foregroundColor(Color("AsaMocha"))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

struct FilterView: View {
    @Bindable var viewModel: FamilyAlbumViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("検索").foregroundColor(Color("AsaCoffeeBrown"))) {
                    TextField("キーワードで検索", text: $viewModel.searchText)
                        .textInputAutocapitalization(.never)
                }
                
                Section(header: Text("フィルター").foregroundColor(Color("AsaCoffeeBrown"))) {
                    Toggle("お気に入りのみ", isOn: $viewModel.showFavoritesOnly)
                        .tint(Color("AsaCoffeeBrown"))
                    
                    Picker("期間", selection: $viewModel.dateFilter) {
                        ForEach(FamilyAlbumViewModel.DateFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(Color("AsaDarkSlate"))
                }
                
                Section {
                    Button("フィルターをクリア") {
                        viewModel.clearSearch()
                    }
                    .foregroundColor(Color("AsaMocha"))
                }
            }
            .navigationTitle("フィルター")
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

struct MonthlyPhotosView: View {
    var viewModel: FamilyAlbumViewModel
    
    var photosByMonth: [(String, [Photo])] {
        let grouped = viewModel.photosByMonth
        return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(photosByMonth, id: \.0) { month, photos in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(month)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .padding(.horizontal, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 8) {
                                ForEach(photos.prefix(20)) { photo in
                                    NavigationLink(destination: PhotoDetailView(photo: photo, viewModel: viewModel)) {
                                        PhotoThumbnailView(photo: photo, viewModel: viewModel)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

#Preview {
    PhotosGridView(viewModel: FamilyAlbumViewModel())
        .modelContainer(for: [Album.self, Photo.self, Comment.self, FamilyMember.self])
}