//
//  NewsListView.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import SwiftUI

struct NewsListView: View {
    @EnvironmentObject var newsViewModel: NewsViewModel
    @EnvironmentObject var feedViewModel: FeedViewModel
    @State private var showingSearchBar = false
    @State private var showingFilterSheet = false
    var showOnlyUnread: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 検索バー
            if showingSearchBar {
                SearchBar(text: $newsViewModel.searchText, onSearchButtonClicked: {
                    newsViewModel.performSearch(newsViewModel.searchText)
                    showingSearchBar = false
                })
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // メインコンテンツ
            if newsViewModel.filteredNewsItems.isEmpty {
                // 記事がない場合
                EmptyNewsView()
            } else {
                // 記事リスト
                List {
                    ForEach(newsViewModel.filteredNewsItems, id: \.id) { newsItem in
                        NavigationLink(destination: NewsDetailView(newsItem: newsItem)) {
                            NewsRowView(newsItem: newsItem)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .onAppear {
                            // 記事を表示したら既読にする（オプション）
                            if !newsItem.isRead {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    newsViewModel.markAsRead(newsItem)
                                }
                            }
                        }
                    }
                    .onDelete(perform: newsViewModel.deleteNewsItems)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await newsViewModel.refreshAllNews()
                }
            }
        }
        .navigationTitle(showOnlyUnread ? "未読記事" : "ニュース")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // 検索ボタン
                Button {
                    showingSearchBar.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                // フィルターボタン
                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: newsViewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                // 更新ボタン
                Button {
                    Task {
                        await newsViewModel.refreshAllNews()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView()
                .environmentObject(newsViewModel)
                .environmentObject(feedViewModel)
        }
        .onAppear {
            if showOnlyUnread {
                newsViewModel.loadUnreadNews()
            } else {
                newsViewModel.loadNews()
            }
        }
        .overlay(
            // ローディング表示
            Group {
                if newsViewModel.isRefreshing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("更新中...")
                            .font(.headline)
                            .padding(.top)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
            }
        )
    }
}

// MARK: - ニュース行ビュー

struct NewsRowView: View {
    let newsItem: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // タイトル
                    Text(newsItem.safeTitle)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(newsItem.isRead ? Color("AsaMutedSage") : Color("AsaDarkSlate"))
                        .lineLimit(2)
                    
                    // コンテンツプレビュー
                    Text(newsItem.contentPreview)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    // メタ情報
                    HStack {
                        // フィード名
                        Text(newsItem.feedTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AsaSoftCream"))
                            .cornerRadius(6)
                        
                        Spacer()
                        
                        // 公開日
                        Text(newsItem.relativePublishedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 新しい記事インジケーター
                        if newsItem.isNew {
                            Circle()
                                .fill(Color("AsaCoffeeBrown"))
                                .frame(width: 8, height: 8)
                        }
                        
                        // 未読インジケーター
                        if !newsItem.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 空の状態ビュー

struct EmptyNewsView: View {
    @EnvironmentObject var newsViewModel: NewsViewModel
    @EnvironmentObject var feedViewModel: FeedViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("記事がありません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
            
            if feedViewModel.activeFeedCount == 0 {
                Text("フィードを追加して\nニュースを読み始めましょう")
                    .font(.body)
                    .foregroundColor(Color("AsaMutedSage"))
                    .multilineTextAlignment(.center)
                
                NavigationLink(destination: AddFeedView()) {
                    Text("フィードを追加")
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color("AsaCoffeeBrown"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Text("フィードを更新して\n新しい記事を取得してください")
                    .font(.body)
                    .foregroundColor(Color("AsaMutedSage"))
                    .multilineTextAlignment(.center)
                
                Button("フィードを更新") {
                    Task {
                        await newsViewModel.refreshAllNews()
                    }
                }
                .buttonStyle(AsaButtonStyle())
            }
        }
        .padding()
    }
}

// MARK: - 検索バー

struct SearchBar: View {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("記事を検索...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button("検索") {
                onSearchButtonClicked()
            }
            .foregroundColor(Color("AsaCoffeeBrown"))
            
            Button("クリア") {
                text = ""
                onSearchButtonClicked()
            }
            .foregroundColor(Color("AsaMocha"))
        }
        .padding(.bottom, 8)
    }
}

// MARK: - フィルターシート

struct FilterSheetView: View {
    @EnvironmentObject var newsViewModel: NewsViewModel
    @EnvironmentObject var feedViewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // 未読フィルター
                Section("表示オプション") {
                    Toggle("未読のみ表示", isOn: $newsViewModel.showOnlyUnread)
                        .tint(Color("AsaCoffeeBrown"))
                }
                
                // フィードフィルター
                Section("フィード") {
                    Button("全て") {
                        newsViewModel.selectedFeed = nil
                        newsViewModel.loadNews()
                    }
                    .foregroundColor(newsViewModel.selectedFeed == nil ? Color("AsaCoffeeBrown") : .primary)
                    
                    ForEach(feedViewModel.feeds, id: \.id) { feed in
                        Button(feed.safeTitle) {
                            newsViewModel.loadNews(for: feed)
                        }
                        .foregroundColor(newsViewModel.selectedFeed == feed ? Color("AsaCoffeeBrown") : .primary)
                    }
                }
                
                // ソートオプション
                Section("並び順") {
                    ForEach(NewsViewModel.SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            newsViewModel.changeSortOption(option)
                        }
                        .foregroundColor(newsViewModel.sortOption == option ? Color("AsaCoffeeBrown") : .primary)
                    }
                }
                
                // アクション
                Section("アクション") {
                    Button("フィルターをクリア") {
                        newsViewModel.clearFilters()
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
        .onChange(of: newsViewModel.showOnlyUnread) { newValue in
            if newValue {
                newsViewModel.loadUnreadNews()
            } else {
                newsViewModel.loadNews()
            }
        }
    }
}

// MARK: - プレビュー

#Preview {
    NavigationView {
        NewsListView()
            .environmentObject(NewsViewModel(context: PersistenceController.preview.container.viewContext))
            .environmentObject(FeedViewModel(context: PersistenceController.preview.container.viewContext))
    }
}