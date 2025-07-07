//
//  ContentView.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import SwiftUI

struct ContentView: View {
    @StateObject private var newsViewModel = NewsViewModel()
    @StateObject private var feedViewModel = FeedViewModel()
    
    var body: some View {
        TabView {
            // ニュースタブ
            NavigationView {
                NewsListView()
                    .environmentObject(newsViewModel)
                    .environmentObject(feedViewModel)
            }
            .tabItem {
                Image(systemName: "newspaper")
                Text("ニュース")
            }
            
            // 未読タブ
            NavigationView {
                UnreadNewsView()
                    .environmentObject(newsViewModel)
                    .environmentObject(feedViewModel)
            }
            .tabItem {
                Image(systemName: "circle")
                Text("未読")
            }
            .badge(newsViewModel.unreadNewsCount > 0 ? newsViewModel.unreadNewsCount : nil)
            
            // フィードタブ
            NavigationView {
                FeedManagementView()
                    .environmentObject(feedViewModel)
                    .environmentObject(newsViewModel)
            }
            .tabItem {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text("フィード")
            }
            
            // 設定タブ
            NavigationView {
                SettingsView()
                    .environmentObject(newsViewModel)
                    .environmentObject(feedViewModel)
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("設定")
            }
        }
        .accentColor(Color("AsaCoffeeBrown"))
        .onAppear {
            setupAppearance()
        }
    }
    
    private func setupAppearance() {
        // タブバーの外観を設定
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
        
        // ナビゲーションバーの外観を設定
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(named: "AsaCoffeeBrown") ?? UIColor.brown
        ]
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(named: "AsaCoffeeBrown") ?? UIColor.brown
        ]
    }
}

// MARK: - 未読ニュースビュー

struct UnreadNewsView: View {
    @EnvironmentObject var newsViewModel: NewsViewModel
    @EnvironmentObject var feedViewModel: FeedViewModel
    
    var body: some View {
        VStack {
            if newsViewModel.unreadNewsCount == 0 {
                // 未読記事がない場合
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("未読記事はありません")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Text("新しい記事を読むために\nフィードを更新してみてください")
                        .font(.body)
                        .foregroundColor(Color("AsaMutedSage"))
                        .multilineTextAlignment(.center)
                    
                    Button("フィードを更新") {
                        Task {
                            await feedViewModel.refreshAllActiveFeeds()
                            newsViewModel.loadNews()
                        }
                    }
                    .buttonStyle(AsaButtonStyle())
                }
                .padding()
            } else {
                // 未読記事がある場合
                NewsListView(showOnlyUnread: true)
            }
        }
        .navigationTitle("未読記事")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            newsViewModel.showOnlyUnread = true
            newsViewModel.loadUnreadNews()
        }
        .onDisappear {
            newsViewModel.showOnlyUnread = false
        }
    }
}

// MARK: - 設定ビュー

struct SettingsView: View {
    @EnvironmentObject var newsViewModel: NewsViewModel
    @EnvironmentObject var feedViewModel: FeedViewModel
    @State private var showingDeleteAlert = false
    @State private var deleteOlderThan = 30 // 日数
    
    var body: some View {
        List {
            // 統計情報セクション
            Section("統計情報") {
                StatRow(title: "フィード数", value: "\(feedViewModel.totalFeedCount)")
                StatRow(title: "アクティブフィード", value: "\(feedViewModel.activeFeedCount)")
                StatRow(title: "記事数", value: "\(newsViewModel.totalNewsCount)")
                StatRow(title: "未読記事", value: "\(newsViewModel.unreadNewsCount)")
                StatRow(title: "今日の記事", value: "\(newsViewModel.todayNewsCount)")
                StatRow(title: "今週の記事", value: "\(newsViewModel.thisWeekNewsCount)")
            }
            
            // アクションセクション
            Section("アクション") {
                Button("全フィードを更新") {
                    Task {
                        await feedViewModel.refreshAllActiveFeeds()
                        newsViewModel.loadNews()
                    }
                }
                .foregroundColor(Color("AsaCoffeeBrown"))
                .disabled(feedViewModel.isLoading)
                
                Button("全記事を既読にする") {
                    newsViewModel.markAllAsRead()
                }
                .foregroundColor(Color("AsaMocha"))
                
                Button("古い記事を削除") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
            }
            
            // アプリ情報セクション
            Section("アプリ情報") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("開発者")
                    Spacer()
                    Text("朝活パパエンジニア")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.large)
        .alert("古い記事を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                newsViewModel.deleteOldNews(olderThan: deleteOlderThan)
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("\(deleteOlderThan)日以上古い記事を削除しますか？この操作は取り消せません。")
        }
    }
}

// MARK: - 統計表示行

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
    }
}

// MARK: - カスタムボタンスタイル

struct AsaButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .fontWeight(.medium)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color("AsaCoffeeBrown"))
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - プレビュー

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
