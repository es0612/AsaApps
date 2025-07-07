//
//  NewsDetailView.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import SwiftUI
import SafariServices

struct NewsDetailView: View {
    let newsItem: NewsItem
    @EnvironmentObject var newsViewModel: NewsViewModel
    @State private var showingSafariView = false
    @State private var showingShareSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー情報
                NewsDetailHeaderSection(newsItem: newsItem)
                
                // 記事内容
                ContentSection(newsItem: newsItem)
                
                // アクションボタン
                ActionSection(
                    newsItem: newsItem,
                    showingSafariView: $showingSafariView,
                    showingShareSheet: $showingShareSheet
                )
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("記事詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // 既読/未読切り替えボタン
                Button {
                    newsViewModel.toggleReadStatus(newsItem)
                } label: {
                    Image(systemName: newsItem.isRead ? "circle" : "checkmark.circle.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                // 共有ボタン
                Button {
                    showingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
        .onAppear {
            // 記事を表示したら既読にする
            if !newsItem.isRead {
                newsViewModel.markAsRead(newsItem)
            }
        }
        .sheet(isPresented: $showingSafariView) {
            SafariView(url: URL(string: newsItem.safeUrl)!)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [newsItem.safeUrl, newsItem.safeTitle])
        }
    }
}

// MARK: - ヘッダーセクション

struct NewsDetailHeaderSection: View {
    let newsItem: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // タイトル
            Text(newsItem.safeTitle)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaDarkSlate"))
                .lineLimit(nil)
            
            // メタ情報
            HStack {
                // フィード名
                Text(newsItem.feedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("AsaSoftCream"))
                    .cornerRadius(8)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // 作者
                    if !newsItem.safeAuthor.isEmpty && newsItem.safeAuthor != "作者不明" {
                        Text("by \(newsItem.safeAuthor)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 公開日
                    Text(newsItem.formattedPublishedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // ステータスインジケーター
            HStack {
                // 新しい記事インジケーター
                if newsItem.isNew {
                    Label("新着", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("AsaCoffeeBrown").opacity(0.1))
                        .cornerRadius(6)
                }
                
                // 既読/未読ステータス
                Label(newsItem.isRead ? "既読" : "未読", systemImage: newsItem.isRead ? "checkmark.circle" : "circle")
                    .font(.caption)
                    .foregroundColor(newsItem.isRead ? Color("AsaMutedSage") : .blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((newsItem.isRead ? Color("AsaMutedSage") : .blue).opacity(0.1))
                    .cornerRadius(6)
                
                Spacer()
            }
        }
        .padding()
        .background(Color("AsaSoftCream").opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - コンテンツセクション

struct ContentSection: View {
    let newsItem: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("記事内容")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            // 記事内容
            Text(newsItem.safeContent)
                .font(.body)
                .lineSpacing(6)
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            // HTMLタグが含まれている場合の警告
            if newsItem.safeContent.contains("<") && newsItem.safeContent.contains(">") {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(Color("AsaMocha"))
                    Text("この記事にはHTML形式のコンテンツが含まれています。完全な表示には「ブラウザで開く」をお試しください。")
                        .font(.caption)
                        .foregroundColor(Color("AsaMocha"))
                }
                .padding()
                .background(Color("AsaMocha").opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - アクションセクション

struct ActionSection: View {
    let newsItem: NewsItem
    @Binding var showingSafariView: Bool
    @Binding var showingShareSheet: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text("アクション")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // ブラウザで開くボタン
                Button {
                    showingSafariView = true
                } label: {
                    HStack {
                        Image(systemName: "safari")
                        Text("ブラウザで開く")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .padding()
                    .background(Color("AsaCoffeeBrown"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // 外部ブラウザで開くボタン
                Button {
                    if let url = URL(string: newsItem.safeUrl) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("外部ブラウザで開く")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .padding()
                    .background(Color("AsaMocha"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // 共有ボタン
                Button {
                    showingShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("共有")
                        Spacer()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .padding()
                    .background(Color("AsaMutedSage"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        return SFSafariViewController(url: url, configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // 更新処理は不要
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 更新処理は不要
    }
}

// MARK: - プレビュー

#Preview {
    NavigationView {
        NewsDetailView(newsItem: {
            let context = PersistenceController.preview.container.viewContext
            let newsItem = NewsItem(context: context)
            newsItem.id = UUID()
            newsItem.title = "SwiftUIの新機能について"
            newsItem.content = "SwiftUIの最新アップデートで追加された新機能についてまとめました。新しいレイアウトシステムやアニメーション機能が追加され、より柔軟で美しいUIが作成できるようになりました。"
            newsItem.author = "朝活パパエンジニア"
            newsItem.publishedDate = Date()
            newsItem.url = "https://asapapalabs.com/swiftui-new-features"
            newsItem.isRead = false
            newsItem.createdAt = Date()
            newsItem.updatedAt = Date()
            return newsItem
        }())
        .environmentObject(NewsViewModel(context: PersistenceController.preview.container.viewContext))
    }
}