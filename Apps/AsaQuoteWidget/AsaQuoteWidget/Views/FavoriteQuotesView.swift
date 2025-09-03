import SwiftUI
import WidgetKit

struct FavoriteQuotesView: View {
    @State private var favoriteQuotes: [Quote] = []
    @State private var selectedQuote: Quote?
    @State private var showingDeleteAlert = false
    @State private var quoteToDelete: Quote?
    
    private let sharedDefaults = SharedDefaults.shared
    
    var body: some View {
        NavigationView {
            Group {
                if favoriteQuotes.isEmpty {
                    emptyStateView
                } else {
                    favoritesList
                }
            }
            .navigationTitle("お気に入り")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !favoriteQuotes.isEmpty {
                        Menu {
                            Button("すべて削除", role: .destructive) {
                                showingDeleteAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                }
            }
            .onAppear {
                loadFavorites()
            }
            .alert("お気に入りを削除", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    if let quote = quoteToDelete {
                        deleteFavorite(quote)
                    } else {
                        deleteAllFavorites()
                    }
                }
            } message: {
                if quoteToDelete != nil {
                    Text("この名言をお気に入りから削除しますか？")
                } else {
                    Text("すべてのお気に入りを削除しますか？この操作は取り消せません。")
                }
            }
            .sheet(item: $selectedQuote) { quote in
                QuoteDetailView(quote: quote)
                    .onDisappear {
                        loadFavorites() // 詳細画面で変更があった場合を考慮
                    }
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart")
                .font(.system(size: 80))
                .foregroundColor(Color("AsaMutedSage").opacity(0.5))
            
            VStack(spacing: 8) {
                Text("お気に入りがありません")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("名言一覧からお気に入りに追加してください")
                    .font(.body)
                    .foregroundColor(Color("AsaMutedSage"))
                    .multilineTextAlignment(.center)
            }
            
            NavigationLink(destination: QuoteListView()) {
                HStack {
                    Image(systemName: "quote.bubble")
                    Text("名言を探す")
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color("AsaCoffeeBrown"))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(40)
    }
    
    // MARK: - Favorites List
    private var favoritesList: some View {
        List {
            ForEach(favoriteQuotes) { quote in
                FavoriteQuoteRow(quote: quote) {
                    selectedQuote = quote
                } onDelete: {
                    quoteToDelete = quote
                    showingDeleteAlert = true
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable {
            loadFavorites()
        }
    }
    
    // MARK: - Methods
    private func loadFavorites() {
        favoriteQuotes = sharedDefaults.favoriteQuotes
    }
    
    private func deleteFavorite(_ quote: Quote) {
        sharedDefaults.removeFavorite(quote)
        loadFavorites()
        quoteToDelete = nil
    }
    
    private func deleteAllFavorites() {
        sharedDefaults.favoriteQuotes = []
        loadFavorites()
    }
}

// MARK: - Favorite Quote Row
struct FavoriteQuoteRow: View {
    let quote: Quote
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // カテゴリアイコン
                VStack {
                    Text(quote.category.emoji)
                        .font(.title2)
                    
                    Text(quote.category.displayName)
                        .font(.caption2)
                        .foregroundColor(Color("AsaMutedSage"))
                        .multilineTextAlignment(.center)
                }
                .frame(width: 60)
                
                // 名言内容
                VStack(alignment: .leading, spacing: 6) {
                    Text(quote.text)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("— \(quote.author)")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                }
                
                Spacer()
                
                // 削除ボタン
                Button(action: onDelete) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("AsaSoftCream").opacity(0.5))
                    .shadow(color: Color("AsaDarkSlate").opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FavoriteQuotesView()
}