//
//  AddBookView.swift
//  AsaBookList
//  
//  Created on 2025/06/27
//

import SwiftUI

struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: BookListViewModel
    
    @State private var title = ""
    @State private var author = ""
    @State private var status = ReadingStatus.toRead
    @State private var notes = ""
    
    var isValidInput: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !author.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("AsaSoftCream")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        AsaCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("新しい本を追加")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("タイトル")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                    
                                    TextField("本のタイトルを入力", text: $title)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("著者")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                    
                                    TextField("著者名を入力", text: $author)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("読書ステータス")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                    
                                    Picker("読書ステータス", selection: $status) {
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
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("メモ（任意）")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                    
                                    TextField("メモを入力", text: $notes, axis: .vertical)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .lineLimit(3...6)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            AsaButton(
                                title: "本を追加",
                                action: addBook,
                                isEnabled: isValidInput
                            )
                            .padding(.horizontal)
                            
                            Button("キャンセル") {
                                dismiss()
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("本を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addBook()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
                }
            }
        }
    }
    
    private func addBook() {
        let newBook = Book(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author.trimmingCharacters(in: .whitespaces),
            status: status,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        
        viewModel.addBook(newBook)
        dismiss()
    }
}

#Preview {
    AddBookView(viewModel: BookListViewModel())
}