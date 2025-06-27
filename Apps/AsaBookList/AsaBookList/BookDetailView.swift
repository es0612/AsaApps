//
//  BookDetailView.swift
//  AsaBookList
//  
//  Created on 2025/06/27
//

import SwiftUI

struct BookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let viewModel: BookListViewModel
    
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editAuthor = ""
    @State private var editStatus = ReadingStatus.toRead
    @State private var editNotes = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("AsaSoftCream")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 基本情報カード
                        AsaCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: book.status.systemImage)
                                        .font(.title)
                                        .foregroundColor(statusColor(for: book.status))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(book.status.rawValue)
                                            .font(.headline)
                                            .foregroundColor(statusColor(for: book.status))
                                        
                                        if book.status == .completed, let dateCompleted = book.dateCompleted {
                                            Text("完読日: \(dateCompleted, style: .date)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                
                                Divider()
                                
                                if isEditing {
                                    VStack(alignment: .leading, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("タイトル")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color("AsaCoffeeBrown"))
                                            TextField("タイトル", text: $editTitle)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("著者")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color("AsaCoffeeBrown"))
                                            TextField("著者", text: $editAuthor)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("読書ステータス")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color("AsaCoffeeBrown"))
                                            
                                            Picker("読書ステータス", selection: $editStatus) {
                                                ForEach(ReadingStatus.allCases, id: \.self) { status in
                                                    HStack {
                                                        Image(systemName: status.systemImage)
                                                        Text(status.rawValue)
                                                    }
                                                    .tag(status)
                                                }
                                            }
                                            .pickerStyle(SegmentedPickerStyle())
                                        }
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("タイトル")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                            Text(book.title)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(Color("AsaCoffeeBrown"))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("著者")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                            Text(book.author)
                                                .font(.title3)
                                                .foregroundColor(Color("AsaCoffeeBrown"))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // メモカード
                        AsaCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("メモ")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                
                                if isEditing {
                                    TextField("メモを入力", text: $editNotes, axis: .vertical)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .lineLimit(5...10)
                                } else {
                                    if book.notes.isEmpty {
                                        Text("メモはありません")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    } else {
                                        Text(book.notes)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // 詳細情報カード
                        AsaCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("詳細情報")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("追加日:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(book.dateAdded, style: .date)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    if book.status == .completed, let dateCompleted = book.dateCompleted {
                                        HStack {
                                            Text("完読日:")
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(dateCompleted, style: .date)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // アクションボタン
                        if !isEditing {
                            VStack(spacing: 12) {
                                if book.status != .completed {
                                    AsaButton(title: "完読済みにする") {
                                        viewModel.updateBookStatus(book, status: .completed)
                                    }
                                    .padding(.horizontal)
                                }
                                
                                Button("編集") {
                                    startEditing()
                                }
                                .foregroundColor(Color("AsaCoffeeBrown"))
                                .fontWeight(.medium)
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("本の詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "キャンセル" : "閉じる") {
                        if isEditing {
                            cancelEditing()
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                if isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("保存") {
                            saveChanges()
                        }
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .fontWeight(.semibold)
                        .disabled(editTitle.trimmingCharacters(in: .whitespaces).isEmpty ||
                                editAuthor.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .toRead:
            return .gray
        case .reading:
            return .blue
        case .completed:
            return .green
        }
    }
    
    private func startEditing() {
        editTitle = book.title
        editAuthor = book.author
        editStatus = book.status
        editNotes = book.notes
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
    }
    
    private func saveChanges() {
        book.title = editTitle.trimmingCharacters(in: .whitespaces)
        book.author = editAuthor.trimmingCharacters(in: .whitespaces)
        book.updateStatus(editStatus)
        book.notes = editNotes.trimmingCharacters(in: .whitespaces)
        
        viewModel.updateBook(book)
        isEditing = false
    }
}

#Preview {
    BookDetailView(
        book: Book(title: "Swift実践入門", author: "増田 亨", status: .reading),
        viewModel: BookListViewModel()
    )
}