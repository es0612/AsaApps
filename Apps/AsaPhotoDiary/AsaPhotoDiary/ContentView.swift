//
//  ContentView.swift
//  AsaPhotoDiary
//  
//  Created on 2025/07/06
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PhotoDiaryViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // 検索バー
                if !viewModel.entries.isEmpty {
                    SearchBar(text: $viewModel.searchText)
                        .onChange(of: viewModel.searchText) { _, _ in
                            viewModel.applyFilters()
                        }
                }
                
                // エントリーリスト
                if viewModel.filteredEntries.isEmpty {
                    EmptyStateView(hasEntries: !viewModel.entries.isEmpty)
                } else {
                    List {
                        ForEach(viewModel.filteredEntries, id: \.id) { entry in
                            NavigationLink(destination: DiaryEntryDetailView(entry: entry, viewModel: viewModel)) {
                                DiaryEntryRowView(entry: entry)
                            }
                        }
                        .onDelete(perform: viewModel.deleteEntries)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("📖 フォト日記")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isShowingAddEntry = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.isShowingFilters = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddEntry) {
                AddEntryView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShowingFilters) {
                FilterView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadEntries()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("日記を検索...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

struct EmptyStateView: View {
    let hasEntries: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasEntries ? "magnifyingglass" : "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(hasEntries ? "検索結果がありません" : "最初の日記を書いてみましょう")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(hasEntries ? "検索条件を変更してください" : "右上の + ボタンをタップして\n新しい日記を作成できます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

struct FilterView: View {
    @ObservedObject var viewModel: PhotoDiaryViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("カテゴリー") {
                    Picker("カテゴリー", selection: $viewModel.selectedCategory) {
                        Text("すべて").tag(DiaryCategory?.none)
                        ForEach(DiaryCategory.allCases, id: \.self) { category in
                            HStack {
                                Text(category.emoji)
                                Text(category.displayName)
                            }
                            .tag(category as DiaryCategory?)
                        }
                    }
                }
                
                Section("気分") {
                    Picker("気分", selection: $viewModel.selectedMood) {
                        Text("すべて").tag(DiaryMood?.none)
                        ForEach(DiaryMood.allCases, id: \.self) { mood in
                            HStack {
                                Text(mood.emoji)
                                Text(mood.displayName)
                            }
                            .tag(mood as DiaryMood?)
                        }
                    }
                }
                
                Section {
                    Button("フィルターをクリア") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
