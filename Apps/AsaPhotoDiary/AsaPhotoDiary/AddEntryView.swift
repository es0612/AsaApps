//
//  AddEntryView.swift
//  AsaPhotoDiary
//  
//  Created on 2025/07/05
//

import SwiftUI
import PhotosUI

struct AddEntryView: View {
    @ObservedObject var viewModel: PhotoDiaryViewModel
    @Environment(\.dismiss) var dismiss
    
    let editingEntry: DiaryEntry?
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: DiaryCategory = .daily
    @State private var selectedMood: DiaryMood = .normal
    @State private var selectedDate: Date = Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?
    
    init(viewModel: PhotoDiaryViewModel, editingEntry: DiaryEntry? = nil) {
        self.viewModel = viewModel
        self.editingEntry = editingEntry
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 写真選択セクション
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Text("写真")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        PhotoPickerView(
                            selectedPhoto: $selectedPhoto,
                            selectedImageData: $selectedImageData,
                            selectedImage: $selectedImage
                        )
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 2)
                    
                    // 基本情報セクション
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Text("基本情報")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("タイトル")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("日記のタイトルを入力", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("内容")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextEditor(text: $content)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("日付")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            DatePicker("日付を選択", selection: $selectedDate, displayedComponents: [.date])
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 2)
                    
                    // カテゴリー・気分セクション
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Text("カテゴリー・気分")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("カテゴリー")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("カテゴリー", selection: $selectedCategory) {
                                ForEach(DiaryCategory.allCases, id: \.self) { category in
                                    HStack {
                                        Text(category.emoji)
                                        Text(category.displayName)
                                    }
                                    .tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("気分")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("気分", selection: $selectedMood) {
                                ForEach(DiaryMood.allCases, id: \.self) { mood in
                                    HStack {
                                        Text(mood.emoji)
                                        Text(mood.displayName)
                                    }
                                    .tag(mood)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 2)
                    
                    // 保存ボタン
                    Button(action: saveEntry) {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.title2)
                            Text(editingEntry == nil ? "日記を保存" : "変更を保存")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            isFormValid ? Color("AsaCoffeeBrown") : Color.gray.opacity(0.5)
                        )
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(Color("AsaSoftCream").opacity(0.3))
            .navigationTitle(editingEntry == nil ? "新しい日記" : "日記を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaMutedSage"))
                }
            }
        }
        .onAppear {
            setupEditingData()
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func setupEditingData() {
        guard let entry = editingEntry else { return }
        
        title = entry.title ?? ""
        content = entry.content ?? ""
        selectedCategory = entry.categoryEnum
        selectedMood = entry.moodEnum
        selectedDate = entry.date ?? Date()
        selectedImageData = entry.imageData
        selectedImage = entry.image
    }
    
    private func saveEntry() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let entry = editingEntry {
            viewModel.updateEntry(
                entry,
                title: trimmedTitle,
                content: trimmedContent,
                category: selectedCategory,
                mood: selectedMood,
                imageData: selectedImageData,
                date: selectedDate
            )
        } else {
            viewModel.createEntry(
                title: trimmedTitle,
                content: trimmedContent,
                category: selectedCategory,
                mood: selectedMood,
                imageData: selectedImageData,
                date: selectedDate
            )
        }
        
        dismiss()
    }
}

#Preview {
    AddEntryView(viewModel: PhotoDiaryViewModel(viewContext: PersistenceController.preview.container.viewContext))
}