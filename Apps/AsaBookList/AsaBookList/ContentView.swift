//
//  ContentView.swift
//  AsaBookList
//  
//  Created on 2025/06/27
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = BookListViewModel()
    @State private var showingAddBook = false
    @State private var selectedBook: Book?
    @State private var showingBookDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("AsaSoftCream")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 統計情報カード
                    AsaCard {
                        VStack(spacing: 8) {
                            Text("読書統計")
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            HStack(spacing: 20) {
                                StatView(title: "未読", count: viewModel.readingStatistics.toRead, color: .gray)
                                StatView(title: "読書中", count: viewModel.readingStatistics.reading, color: .blue)
                                StatView(title: "完読", count: viewModel.readingStatistics.completed, color: .green)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // フィルター
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterButton(title: "すべて", isSelected: viewModel.selectedFilter == nil) {
                                viewModel.selectedFilter = nil
                            }
                            
                            ForEach(ReadingStatus.allCases, id: \.self) { status in
                                FilterButton(title: status.rawValue, isSelected: viewModel.selectedFilter == status) {
                                    viewModel.selectedFilter = status
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    
                    // 本のリスト
                    if viewModel.filteredBooks.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 60))
                                .foregroundColor(Color("AsaCoffeeBrown").opacity(0.5))
                            
                            Text("本がありません")
                                .font(.title2)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            Text("「+」ボタンで本を追加してください")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.filteredBooks) { book in
                                BookRowView(book: book, onStatusChange: { newStatus in
                                    viewModel.updateBookStatus(book, status: newStatus)
                                }, onTap: {
                                    selectedBook = book
                                    showingBookDetail = true
                                })
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteBooks)
                        }
                        .listStyle(PlainListStyle())
                        .background(Color.clear)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("読書リスト")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddBook = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingBookDetail) {
            if let book = selectedBook {
                BookDetailView(book: book, viewModel: viewModel)
            }
        }
    }
    
    private func deleteBooks(offsets: IndexSet) {
        for index in offsets {
            let book = viewModel.filteredBooks[index]
            viewModel.deleteBook(book)
        }
    }
}

struct StatView: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color("AsaCoffeeBrown") : Color.clear)
                .foregroundColor(isSelected ? .white : Color("AsaCoffeeBrown"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("AsaCoffeeBrown"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    ContentView()
}
