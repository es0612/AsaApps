//
//  StockListView.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import SwiftUI

struct StockListView: View {
    @Environment(StockViewModel.self) private var stockViewModel
    @Environment(WatchListViewModel.self) private var watchListViewModel
    @State private var showingAddStock = false
    @State private var selectedStock: Stock?
    
    var body: some View {
        @Bindable var watchListVM = watchListViewModel
        
        List {
            if watchListViewModel.sortedStocks.isEmpty {
                EmptyWatchListView {
                    showingAddStock = true
                }
            } else {
                // お気に入り銘柄セクション
                let favorites = watchListViewModel.sortedStocks.filter { 
                    watchListViewModel.isFavorite($0) 
                }
                if !favorites.isEmpty {
                    Section("お気に入り") {
                        ForEach(favorites) { stock in
                            StockRowView(stock: stock, isFavorite: true)
                                .onTapGesture {
                                    selectedStock = stock
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            watchListViewModel.removeFromWatchList(stock)
                                        }
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        watchListViewModel.toggleFavorite(stock)
                                    } label: {
                                        Label("お気に入り解除", systemImage: "star.slash")
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                }
                
                // その他の銘柄セクション
                let others = watchListViewModel.sortedStocks.filter { 
                    !watchListViewModel.isFavorite($0) 
                }
                if !others.isEmpty {
                    Section("ウォッチリスト") {
                        ForEach(others) { stock in
                            StockRowView(stock: stock, isFavorite: false)
                                .onTapGesture {
                                    selectedStock = stock
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            watchListViewModel.removeFromWatchList(stock)
                                        }
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        watchListViewModel.toggleFavorite(stock)
                                    } label: {
                                        Label("お気に入り", systemImage: "star")
                                    }
                                    .tint(.yellow)
                                }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            await watchListViewModel.refreshWatchList()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
                    .disabled(watchListViewModel.sortedStocks.isEmpty)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddStock = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!watchListViewModel.canAddMoreStocks)
            }
            
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(StockViewModel.SortOption.allCases, id: \.self) { option in
                        Button {
                            watchListViewModel.setSortOption(option)
                        } label: {
                            if watchListViewModel.sortOption == option {
                                Label(option.rawValue, systemImage: "checkmark")
                            } else {
                                Text(option.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("並び替え")
                            .font(.caption)
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingAddStock) {
            SearchView(isPresented: $showingAddStock)
                .environment(stockViewModel)
                .environment(watchListViewModel)
        }
        .sheet(item: $selectedStock) { stock in
            StockDetailView(stock: stock)
                .environment(stockViewModel)
        }
    }
}

// MARK: - Empty Watch List View
struct EmptyWatchListView: View {
    let onAddStock: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("ウォッチリストが空です")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("銘柄を追加して\n株価をトラッキングしましょう")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onAddStock) {
                Label("銘柄を追加", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.776, green: 0.549, blue: 0.325))  // AsaCoffeeBrown
                    .cornerRadius(Constants.UI.cornerRadius)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StockListView()
            .environment(StockViewModel())
            .environment(WatchListViewModel())
            .navigationTitle("ウォッチリスト")
    }
}