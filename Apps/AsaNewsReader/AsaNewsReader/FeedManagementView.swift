//
//  FeedManagementView.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import SwiftUI

struct FeedManagementView: View {
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var newsViewModel: NewsViewModel
    @State private var showingAddFeed = false
    @State private var showingEditFeed = false
    @State private var selectedFeed: RSSFeed?
    @State private var showingSortOptions = false
    
    var body: some View {
        VStack(spacing: 0) {
            if feedViewModel.feeds.isEmpty {
                // フィードがない場合
                EmptyFeedView()
            } else {
                // フィードリスト
                List {
                    ForEach(feedViewModel.feeds, id: \.id) { feed in
                        FeedRowView(
                            feed: feed,
                            onEdit: { editFeed(feed) },
                            onToggleStatus: { feedViewModel.toggleFeedActiveStatus(feed) },
                            onRefresh: { refreshFeed(feed) },
                            onViewNews: { viewNews(for: feed) }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: feedViewModel.deleteFeeds)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await feedViewModel.refresh()
                }
            }
        }
        .navigationTitle("フィード管理")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // ソートボタン
                Button {
                    showingSortOptions = true
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                // 全更新ボタン
                Button {
                    Task {
                        await feedViewModel.refreshAllActiveFeeds()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                // 追加ボタン
                Button {
                    showingAddFeed = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
        .sheet(isPresented: $showingAddFeed) {
            AddFeedView()
                .environmentObject(feedViewModel)
        }
        .sheet(isPresented: $showingEditFeed) {
            if let feed = selectedFeed {
                EditFeedView(feed: feed)
                    .environmentObject(feedViewModel)
            }
        }
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(
                title: Text("並び順"),
                buttons: FeedViewModel.SortOption.allCases.map { option in
                    .default(Text(option.rawValue)) {
                        feedViewModel.changeSortOption(option)
                    }
                } + [.cancel()]
            )
        }
        .overlay(
            // ローディング表示
            Group {
                if feedViewModel.isLoading {
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
        .onAppear {
            feedViewModel.loadFeeds()
        }
    }
    
    private func editFeed(_ feed: RSSFeed) {
        selectedFeed = feed
        showingEditFeed = true
    }
    
    private func refreshFeed(_ feed: RSSFeed) {
        Task {
            await feedViewModel.refreshFeed(feed)
        }
    }
    
    private func viewNews(for feed: RSSFeed) {
        newsViewModel.loadNews(for: feed)
    }
}

// MARK: - フィード行ビュー

struct FeedRowView: View {
    let feed: RSSFeed
    let onEdit: () -> Void
    let onToggleStatus: () -> Void
    let onRefresh: () -> Void
    let onViewNews: () -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // タイトルとステータス
                    HStack {
                        Text(feed.safeTitle)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(feed.isActive ? Color("AsaDarkSlate") : Color("AsaMutedSage"))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // ステータスバッジ
                        Text(feed.statusText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(for: feed))
                            .cornerRadius(6)
                    }
                    
                    // 説明
                    if !feed.safeDescription.isEmpty {
                        Text(feed.safeDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // 統計情報
                    HStack {
                        Label("\(feed.newsItemCount)", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Label("\(feed.unreadNewsItemCount)", systemImage: "circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        // 最終更新日
                        Text(feed.relativeLastFetched)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // アクションボタン
                Button {
                    showingActionSheet = true
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .padding(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .padding(.vertical, 4)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(feed.safeTitle),
                buttons: [
                    .default(Text("記事を表示")) { onViewNews() },
                    .default(Text("更新")) { onRefresh() },
                    .default(Text("編集")) { onEdit() },
                    .default(Text(feed.isActive ? "無効にする" : "有効にする")) { onToggleStatus() },
                    .default(Text("全記事を既読にする")) {
                        feedViewModel.markAllNewsAsRead(feed)
                    },
                    .destructive(Text("削除")) {
                        feedViewModel.deleteFeed(feed)
                    },
                    .cancel()
                ]
            )
        }
    }
    
    @EnvironmentObject var feedViewModel: FeedViewModel
    
    private func statusColor(for feed: RSSFeed) -> Color {
        if !feed.isActive {
            return .gray
        } else if feed.lastFetched == nil {
            return .orange
        } else if feed.isRecentlyUpdated {
            return .green
        } else {
            return Color("AsaMocha")
        }
    }
}

// MARK: - 空の状態ビュー

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("フィードがありません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("RSSフィードを追加して\nニュースの配信を開始しましょう")
                .font(.body)
                .foregroundColor(Color("AsaMutedSage"))
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: AddFeedView()) {
                Text("最初のフィードを追加")
                    .font(.body)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color("AsaCoffeeBrown"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - フィード編集ビュー

struct EditFeedView: View {
    let feed: RSSFeed
    @EnvironmentObject var feedViewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("タイトル", text: $title)
                    TextField("説明", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("URL") {
                    Text(feed.safeUrl)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                
                Section("統計") {
                    HStack {
                        Text("記事数")
                        Spacer()
                        Text("\(feed.newsItemCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("未読記事数")
                        Spacer()
                        Text("\(feed.unreadNewsItemCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("最終更新")
                        Spacer()
                        Text(feed.formattedLastFetched)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("ステータス")
                        Spacer()
                        Text(feed.statusText)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("アクション") {
                    Button("フィードを更新") {
                        Task {
                            await feedViewModel.refreshFeed(feed)
                        }
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Button("全記事を既読にする") {
                        feedViewModel.markAllNewsAsRead(feed)
                    }
                    .foregroundColor(Color("AsaMocha"))
                    
                    Button("古い記事を削除 (30日以上)") {
                        feedViewModel.deleteOldNews(feed, olderThan: 30)
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("フィード編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaMocha"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        feedViewModel.updateFeed(feed, title: title, description: description)
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
        .onAppear {
            title = feed.safeTitle
            description = feed.safeDescription
        }
    }
}

// MARK: - プレビュー

#Preview {
    NavigationView {
        FeedManagementView()
            .environmentObject(FeedViewModel(context: PersistenceController.preview.container.viewContext))
            .environmentObject(NewsViewModel(context: PersistenceController.preview.container.viewContext))
    }
}