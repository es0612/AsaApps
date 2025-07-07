//
//  AddFeedView.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import SwiftUI

struct AddFeedView: View {
    @EnvironmentObject var feedViewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var feedURL: String = ""
    @State private var customTitle: String = ""
    @State private var customDescription: String = ""
    @State private var useCustomInfo = false
    @State private var showingPreview = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    AddFeedHeaderSection()
                    
                    // URL入力セクション
                    URLInputSection(
                        feedURL: $feedURL,
                        onValidate: validateFeed
                    )
                    
                    // 検証結果プレビュー
                    if feedViewModel.hasValidationResult {
                        ValidationResultSection(
                            feedInfo: feedViewModel.feedValidationResult!,
                            useCustomInfo: $useCustomInfo,
                            customTitle: $customTitle,
                            customDescription: $customDescription
                        )
                    }
                    
                    // カスタム情報セクション
                    if useCustomInfo {
                        CustomInfoSection(
                            customTitle: $customTitle,
                            customDescription: $customDescription
                        )
                    }
                    
                    // 追加ボタン
                    if feedViewModel.hasValidationResult {
                        AddButton(
                            isLoading: feedViewModel.isLoading,
                            onAdd: addFeed
                        )
                    }
                    
                    // サンプルフィード
                    SampleFeedsSection(onSelectSample: { url in
                        feedURL = url
                        validateFeed()
                    })
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("フィード追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaMocha"))
                }
            }
            .alert("エラー", isPresented: .constant(feedViewModel.hasError)) {
                Button("OK") {
                    feedViewModel.clearError()
                }
            } message: {
                Text(feedViewModel.errorMessage ?? "")
            }
            .overlay(
                // ローディング表示
                Group {
                    if feedViewModel.isValidatingFeed {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("フィードを検証中...")
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
    
    private func validateFeed() {
        guard !feedURL.isEmpty else { return }
        Task {
            await feedViewModel.validateFeedURL(feedURL)
        }
    }
    
    private func addFeed() {
        let title = useCustomInfo && !customTitle.isEmpty ? customTitle : nil
        let description = useCustomInfo && !customDescription.isEmpty ? customDescription : nil
        
        Task {
            await feedViewModel.addFeed(
                url: feedURL,
                title: title,
                description: description
            )
            
            if !feedViewModel.hasError {
                dismiss()
            }
        }
    }
}

// MARK: - ヘッダーセクション

struct AddFeedHeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 40))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text("新しいRSSフィードを追加")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("RSSフィードのURLを入力してください")
                .font(.body)
                .foregroundColor(Color("AsaMutedSage"))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color("AsaSoftCream").opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - URL入力セクション

struct URLInputSection: View {
    @Binding var feedURL: String
    let onValidate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("フィードURL")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            TextField("https://example.com/feed.xml", text: $feedURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onSubmit {
                    onValidate()
                }
            
            HStack {
                Button("検証") {
                    onValidate()
                }
                .buttonStyle(AsaButtonStyle())
                .disabled(feedURL.isEmpty)
                
                Button("クリア") {
                    feedURL = ""
                }
                .foregroundColor(Color("AsaMocha"))
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 検証結果セクション

struct ValidationResultSection: View {
    let feedInfo: RSSFeedInfo
    @Binding var useCustomInfo: Bool
    @Binding var customTitle: String
    @Binding var customDescription: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("フィードの検証が成功しました")
                    .font(.headline)
                    .foregroundColor(Color("AsaDarkSlate"))
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                FeedInfoRow(title: "タイトル", value: feedInfo.title)
                FeedInfoRow(title: "説明", value: feedInfo.description)
                FeedInfoRow(title: "リンク", value: feedInfo.link)
            }
            
            Toggle("カスタム情報を使用", isOn: $useCustomInfo)
                .tint(Color("AsaCoffeeBrown"))
            
            if useCustomInfo {
                Text("フィードのタイトルと説明をカスタマイズできます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            // デフォルト値を設定
            if customTitle.isEmpty {
                customTitle = feedInfo.title
            }
            if customDescription.isEmpty {
                customDescription = feedInfo.description
            }
        }
    }
}

// MARK: - カスタム情報セクション

struct CustomInfoSection: View {
    @Binding var customTitle: String
    @Binding var customDescription: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カスタム情報")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("タイトル")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("フィードのタイトル", text: $customTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("説明")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("フィードの説明", text: $customDescription, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 追加ボタン

struct AddButton: View {
    let isLoading: Bool
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                Text(isLoading ? "追加中..." : "フィードを追加")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading ? Color.gray : Color("AsaCoffeeBrown"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

// MARK: - サンプルフィードセクション

struct SampleFeedsSection: View {
    let onSelectSample: (String) -> Void
    
    private let sampleFeeds = [
        ("朝活パパエンジニアブログ", "https://asapapalabs.com/feed/"),
        ("TechCrunch Japan", "https://techcrunch.com/feed/"),
        ("Qiita トレンド", "https://qiita.com/popular-items/feed"),
        ("はてなブックマーク テクノロジー", "https://b.hatena.ne.jp/hotentry/it.rss"),
        ("Yahoo! ニュース", "https://news.yahoo.co.jp/rss/topics/top-picks.xml")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("サンプルフィード")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("以下のサンプルフィードを試すことができます")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(sampleFeeds, id: \.0) { name, url in
                    Button(name) {
                        onSelectSample(url)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("AsaMutedSage").opacity(0.2))
                    .foregroundColor(Color("AsaDarkSlate"))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - フィード情報行

struct FeedInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(value.isEmpty ? "情報なし" : value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
    }
}

// MARK: - プレビュー

#Preview {
    AddFeedView()
        .environmentObject(FeedViewModel(context: PersistenceController.preview.container.viewContext))
}