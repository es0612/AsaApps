import SwiftUI
import WidgetKit

struct QuoteListView: View {
    @State private var quotes: [Quote] = []
    @State private var filteredQuotes: [Quote] = []
    @State private var selectedCategory: QuoteCategory = .encouragement
    @State private var searchText = ""
    @State private var showingQuoteDetail = false
    @State private var selectedQuote: Quote?
    
    private let dataProvider = QuoteDataProvider.shared
    private let sharedDefaults = SharedDefaults.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // カテゴリフィルター
                categoryFilterView
                
                // 名言リスト
                quotesList
            }
            .navigationTitle("名言集")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "名言を検索...")
            .onAppear {
                loadQuotes()
                selectedCategory = sharedDefaults.selectedCategory
            }
            .onChange(of: selectedCategory) { category in
                sharedDefaults.selectedCategory = category
                filterQuotes()
                WidgetCenter.shared.reloadAllTimelines()
            }
            .onChange(of: searchText) { _ in
                filterQuotes()
            }
            .sheet(item: $selectedQuote) { quote in
                QuoteDetailView(quote: quote)
            }
        }
    }
    
    // MARK: - Category Filter View
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(QuoteCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        category: category,
                        isSelected: category == selectedCategory
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color("AsaSoftCream").opacity(0.3))
    }
    
    // MARK: - Quotes List
    private var quotesList: some View {
        List(filteredQuotes) { quote in
            QuoteRowView(quote: quote) {
                selectedQuote = quote
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
    
    // MARK: - Methods
    private func loadQuotes() {
        quotes = dataProvider.getAllQuotes()
        filterQuotes()
    }
    
    private func filterQuotes() {
        var result = quotes
        
        // カテゴリフィルター
        result = result.filter { $0.category == selectedCategory }
        
        // 検索フィルター
        if !searchText.isEmpty {
            result = result.filter { quote in
                quote.text.localizedCaseInsensitiveContains(searchText) ||
                quote.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredQuotes = result
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let category: QuoteCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.emoji)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color("AsaCoffeeBrown") : Color("AsaMutedSage").opacity(0.3))
            )
            .foregroundColor(isSelected ? .white : Color("AsaDarkSlate"))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quote Row View
struct QuoteRowView: View {
    let quote: Quote
    let action: () -> Void
    @State private var isFavorite = false
    
    private let sharedDefaults = SharedDefaults.shared
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quote.text)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                        
                        Text("— \(quote.author)")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    Spacer()
                    
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? Color("AsaCoffeeBrown") : Color("AsaMutedSage"))
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("AsaSoftCream").opacity(0.5))
                    .shadow(color: Color("AsaDarkSlate").opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            isFavorite = sharedDefaults.isFavorite(quote)
        }
    }
    
    private func toggleFavorite() {
        if isFavorite {
            sharedDefaults.removeFavorite(quote)
        } else {
            sharedDefaults.addFavorite(quote)
        }
        isFavorite.toggle()
    }
}

#Preview {
    QuoteListView()
}