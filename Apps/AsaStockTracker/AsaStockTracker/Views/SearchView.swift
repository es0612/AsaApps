//
//  SearchView.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import SwiftUI

struct SearchView: View {
    @Environment(StockViewModel.self) private var stockViewModel
    @Environment(WatchListViewModel.self) private var watchListViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var isSearching = false
    
    init(isPresented: Binding<Bool> = .constant(false)) {
        self._isPresented = isPresented
    }
    
    var body: some View {
        @Bindable var stockVM = stockViewModel
        
        VStack {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("銘柄名またはシンボルを入力", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        stockViewModel.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            // 検索結果
            if isSearching {
                ProgressView("検索中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if stockViewModel.searchResults.isEmpty && !searchText.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("検索結果がありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("別のキーワードで\n検索してみてください")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if !stockViewModel.searchResults.isEmpty {
                List(stockViewModel.searchResults) { result in
                    SearchResultRow(
                        result: result,
                        isInWatchList: watchListViewModel.watchList.contains(symbol: result.symbol)
                    ) {
                        Task {
                            await watchListViewModel.addFromSearch(result)
                            
                            // モーダルの場合は閉じる
                            if isPresented {
                                isPresented = false
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                // 人気銘柄の提案
                SuggestedStocksView { symbol in
                    searchText = symbol
                    performSearch()
                }
            }
            
            Spacer()
        }
        .navigationTitle(isPresented ? "銘柄を追加" : "銘柄検索")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isPresented {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        stockViewModel.searchText = searchText
        
        Task {
            await stockViewModel.searchSymbols()
            isSearching = false
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResult
    let isInWatchList: Bool
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.symbol)
                    .font(.headline)
                
                Text(result.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(result.type, systemImage: "tag")
                    Label(result.region, systemImage: "globe")
                    Label(result.currency, systemImage: "dollarsign.circle")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isInWatchList {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(red: 0.776, green: 0.549, blue: 0.325))  // AsaCoffeeBrown
                        .font(.title2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Suggested Stocks View
struct SuggestedStocksView: View {
    let onSelect: (String) -> Void
    
    let suggestions = [
        ("AAPL", "Apple"),
        ("GOOGL", "Google"),
        ("MSFT", "Microsoft"),
        ("AMZN", "Amazon"),
        ("TSLA", "Tesla"),
        ("META", "Meta"),
        ("NVDA", "NVIDIA"),
        ("JPM", "JPMorgan"),
        ("V", "Visa"),
        ("JNJ", "Johnson & Johnson")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("人気の銘柄")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(suggestions, id: \.0) { symbol, name in
                        Button {
                            onSelect(symbol)
                        } label: {
                            VStack(spacing: 8) {
                                Text(symbol)
                                    .font(.headline)
                                
                                Text(name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SearchView()
            .environment(StockViewModel())
            .environment(WatchListViewModel())
    }
}