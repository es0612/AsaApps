//
//  SearchView.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Bindable var viewModel: FamilyAlbumViewModel
    @State private var searchScope: SearchScope = .all
    @State private var selectedDateRange = DateRange.all
    @State private var showingAdvancedSearch = false
    
    enum SearchScope: String, CaseIterable {
        case all = "すべて"
        case albums = "アルバム"
        case photos = "写真"
        case members = "家族"
    }
    
    enum DateRange: String, CaseIterable {
        case all = "すべて"
        case today = "今日"
        case thisWeek = "今週"
        case thisMonth = "今月"
        case thisYear = "今年"
        
        var dateFilter: FamilyAlbumViewModel.DateFilter {
            switch self {
            case .all: return .all
            case .today: return .today
            case .thisWeek: return .thisWeek
            case .thisMonth: return .thisMonth
            case .thisYear: return .thisYear
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        TextField("検索...", text: $viewModel.searchText)
                            .textInputAutocapitalization(.never)
                            .onSubmit {
                                Task {
                                    await viewModel.searchPhotos(text: viewModel.searchText)
                                }
                            }
                        
                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.clearSearch()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color("AsaMutedSage"))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color("AsaSoftCream").opacity(0.5))
                    .cornerRadius(10)
                    
                    // スコープセレクター
                    Picker("検索範囲", selection: $searchScope) {
                        ForEach(SearchScope.allCases, id: \.self) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // フィルターバー
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 日付フィルター
                        Menu {
                            Picker("期間", selection: $selectedDateRange) {
                                ForEach(DateRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text(selectedDateRange.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedDateRange != .all ? Color("AsaCoffeeBrown").opacity(0.8) : Color("AsaMutedSage").opacity(0.3))
                            .foregroundColor(selectedDateRange != .all ? .white : Color("AsaDarkSlate"))
                            .cornerRadius(16)
                        }
                        .onChange(of: selectedDateRange) { _, newValue in
                            viewModel.dateFilter = newValue.dateFilter
                        }
                        
                        // お気に入りフィルター
                        Button {
                            viewModel.showFavoritesOnly.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                                Text("お気に入り")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.showFavoritesOnly ? Color("AsaCoffeeBrown").opacity(0.8) : Color("AsaMutedSage").opacity(0.3))
                            .foregroundColor(viewModel.showFavoritesOnly ? .white : Color("AsaDarkSlate"))
                            .cornerRadius(16)
                        }
                        
                        // 高度な検索
                        Button {
                            showingAdvancedSearch = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                Text("詳細")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color("AsaMutedSage").opacity(0.3))
                            .foregroundColor(Color("AsaDarkSlate"))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // 検索結果
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    SearchResultsView(
                        scope: searchScope,
                        viewModel: viewModel
                    )
                }
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAdvancedSearch) {
                AdvancedSearchView(viewModel: viewModel)
            }
        }
    }
}

struct SearchResultsView: View {
    let scope: SearchView.SearchScope
    var viewModel: FamilyAlbumViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                switch scope {
                case .all:
                    SearchAllResultsView(viewModel: viewModel)
                case .albums:
                    SearchAlbumsResultsView(viewModel: viewModel)
                case .photos:
                    SearchPhotosResultsView(viewModel: viewModel)
                case .members:
                    SearchMembersResultsView(viewModel: viewModel)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

struct SearchAllResultsView: View {
    var viewModel: FamilyAlbumViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // アルバム結果
            if !viewModel.filteredAlbums.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("アルバム")
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Spacer()
                        
                        Text("\(viewModel.filteredAlbums.count)件")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    ForEach(viewModel.filteredAlbums.prefix(3)) { album in
                        NavigationLink(destination: AlbumDetailView(album: album, viewModel: viewModel)) {
                            AlbumSearchRow(album: album, viewModel: viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // 写真結果
            if !viewModel.filteredPhotos.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("写真")
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Spacer()
                        
                        Text("\(viewModel.filteredPhotos.count)枚")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(viewModel.filteredPhotos.prefix(6)) { photo in
                            NavigationLink(destination: PhotoDetailView(photo: photo, viewModel: viewModel)) {
                                PhotoThumbnailView(photo: photo, viewModel: viewModel)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }
            
            // 空の状態
            if viewModel.filteredAlbums.isEmpty && viewModel.filteredPhotos.isEmpty && !viewModel.searchText.isEmpty {
                EmptySearchResultsView()
            }
        }
    }
}

struct SearchAlbumsResultsView: View {
    var viewModel: FamilyAlbumViewModel
    
    var body: some View {
        if viewModel.filteredAlbums.isEmpty {
            EmptySearchResultsView()
        } else {
            ForEach(viewModel.filteredAlbums) { album in
                NavigationLink(destination: AlbumDetailView(album: album, viewModel: viewModel)) {
                    AlbumSearchRow(album: album, viewModel: viewModel)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct SearchPhotosResultsView: View {
    var viewModel: FamilyAlbumViewModel
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
    
    var body: some View {
        if viewModel.filteredPhotos.isEmpty {
            EmptySearchResultsView()
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.filteredPhotos) { photo in
                    NavigationLink(destination: PhotoDetailView(photo: photo, viewModel: viewModel)) {
                        PhotoThumbnailView(photo: photo, viewModel: viewModel)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
}

struct SearchMembersResultsView: View {
    var viewModel: FamilyAlbumViewModel
    
    var filteredMembers: [FamilyMember] {
        if viewModel.searchText.isEmpty {
            return viewModel.familyMembers
        }
        
        return viewModel.familyMembers.filter { member in
            member.name.localizedStandardContains(viewModel.searchText) ||
            member.nickname?.localizedStandardContains(viewModel.searchText) == true ||
            member.relationship.localizedStandardContains(viewModel.searchText)
        }
    }
    
    var body: some View {
        if filteredMembers.isEmpty {
            EmptySearchResultsView()
        } else {
            ForEach(filteredMembers) { member in
                NavigationLink(destination: FamilyMemberDetailView(member: member, viewModel: viewModel)) {
                    FamilyMemberCard(member: member)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct AlbumSearchRow: View {
    let album: Album
    var viewModel: FamilyAlbumViewModel
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        HStack(spacing: 12) {
            // サムネイル
            ZStack {
                Rectangle()
                    .fill(Color("AsaMutedSage").opacity(0.3))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            .task {
                if let recentPhoto = album.recentPhotos.first {
                    thumbnailImage = await viewModel.loadImage(for: recentPhoto, size: CGSize(width: 60, height: 60))
                }
            }
            
            // 情報
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.headline)
                    .foregroundColor(Color("AsaDarkSlate"))
                    .lineLimit(1)
                
                Text("\(album.photoCount)枚の写真")
                    .font(.caption)
                    .foregroundColor(Color("AsaMocha"))
                
                if let description = album.albumDescription {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(Color("AsaMutedSage"))
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color("AsaDarkSlate").opacity(0.1), radius: 2)
    }
}

struct EmptySearchResultsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("検索結果がありません")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("別のキーワードで\n検索してみてください")
                .font(.body)
                .foregroundColor(Color("AsaMocha"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
}

struct AdvancedSearchView: View {
    @Bindable var viewModel: FamilyAlbumViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("検索条件").foregroundColor(Color("AsaCoffeeBrown"))) {
                    TextField("キーワード", text: $viewModel.searchText)
                        .textInputAutocapitalization(.never)
                }
                
                Section(header: Text("期間").foregroundColor(Color("AsaCoffeeBrown"))) {
                    Picker("期間フィルター", selection: $viewModel.dateFilter) {
                        ForEach(FamilyAlbumViewModel.DateFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("オプション").foregroundColor(Color("AsaCoffeeBrown"))) {
                    Toggle("お気に入りのみ", isOn: $viewModel.showFavoritesOnly)
                        .tint(Color("AsaCoffeeBrown"))
                }
                
                Section {
                    Button("検索をクリア") {
                        viewModel.clearSearch()
                    }
                    .foregroundColor(Color("AsaMocha"))
                }
            }
            .navigationTitle("詳細検索")
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

#Preview {
    SearchView(viewModel: FamilyAlbumViewModel())
        .modelContainer(for: [Album.self, Photo.self, Comment.self, FamilyMember.self])
}