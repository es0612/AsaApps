//
//  GratitudeHistoryView.swift
//  AsaGratitude
//  
//  Created on 2025/07/02
//

import SwiftUI

struct GratitudeHistoryView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    @State private var searchText = ""
    @State private var selectedCategory: GratitudeCategory?
    @State private var showingFilterSheet = false
    
    var filteredEntries: [GratitudeEntry] {
        var entries = viewModel.gratitudeEntries
        
        // カテゴリーでフィルター
        if let selectedCategory = selectedCategory {
            entries = entries.filter { $0.category == selectedCategory }
        }
        
        // 検索テキストでフィルター
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.content.localizedCaseInsensitiveContains(searchText) ||
                entry.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return entries
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 検索とフィルターセクション
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("感謝の内容を検索", text: $searchText)
                    
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: selectedCategory == nil ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(selectedCategory == nil ? .secondary : Color("AsaCoffeeBrown"))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // アクティブなフィルター表示
                if let selectedCategory = selectedCategory {
                    HStack {
                        Text("フィルター:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text(selectedCategory.emoji)
                            Text(selectedCategory.displayName)
                            Button(action: {
                                self.selectedCategory = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(selectedCategory.color).opacity(0.2))
                        .foregroundColor(Color(selectedCategory.color))
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            Divider()
            
            // 感謝履歴リスト
            if filteredEntries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 50))
                        .foregroundColor(Color("AsaMutedSage").opacity(0.5))
                    
                    if searchText.isEmpty && selectedCategory == nil {
                        Text("感謝の記録がありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("最初の感謝を記録してみましょう！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("条件に一致する記録がありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("検索条件やフィルターを変更してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        GratitudeDetailRowView(entry: entry)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete(perform: deleteEntries)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("感謝の履歴")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView(selectedCategory: $selectedCategory)
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        let entriesToDelete = offsets.map { filteredEntries[$0] }
        for entry in entriesToDelete {
            viewModel.deleteGratitudeEntry(entry)
        }
    }
}

struct GratitudeDetailRowView: View {
    let entry: GratitudeEntry
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack {
                        Text(entry.category.emoji)
                            .font(.title)
                        Text(entry.moodLevel.emoji)
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.content)
                            .font(.body)
                            .lineLimit(nil)
                        
                        HStack {
                            Text(entry.category.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(entry.category.color).opacity(0.2))
                                .foregroundColor(Color(entry.category.color))
                                .cornerRadius(8)
                            
                            Text(entry.moodLevel.stars)
                                .font(.caption)
                            
                            Spacer()
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                HStack {
                    Text("\(entry.dateFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(entry.timeFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct FilterSheetView: View {
    @Binding var selectedCategory: GratitudeCategory?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("カテゴリーでフィルター")) {
                    // すべて表示オプション
                    Button(action: {
                        selectedCategory = nil
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text("✨")
                                .font(.title2)
                            Text("すべて表示")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                        }
                    }
                    
                    // 各カテゴリーオプション
                    ForEach(GratitudeCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(category.emoji)
                                    .font(.title2)
                                Text(category.displayName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完了") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    NavigationView {
        GratitudeHistoryView(viewModel: GratitudeViewModel())
    }
}