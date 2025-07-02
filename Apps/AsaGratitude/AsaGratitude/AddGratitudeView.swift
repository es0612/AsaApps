//
//  AddGratitudeView.swift
//  AsaGratitude
//  
//  Created on 2025/07/02
//

import SwiftUI

struct AddGratitudeView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var content = ""
    @State private var selectedCategory: GratitudeCategory = .general
    @State private var selectedMood: GratitudeMood = .grateful
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("感謝の内容")) {
                    TextField("今日感謝していることを書いてください", text: $content, axis: .vertical)
                        .lineLimit(3...8)
                        .frame(minHeight: 80)
                }
                
                Section(header: Text("カテゴリー")) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(GratitudeCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                VStack(spacing: 4) {
                                    Text(category.emoji)
                                        .font(.title2)
                                    Text(category.displayName)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    selectedCategory == category ?
                                    Color(category.color).opacity(0.3) :
                                    Color.gray.opacity(0.1)
                                )
                                .foregroundColor(
                                    selectedCategory == category ?
                                    Color(category.color) :
                                    .primary
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section(header: Text("感謝の気持ち")) {
                    Picker("気持ちの強さ", selection: $selectedMood) {
                        ForEach(GratitudeMood.allCases, id: \.self) { mood in
                            HStack {
                                Text(mood.emoji)
                                Text(mood.displayName)
                                Spacer()
                                Text(mood.stars)
                            }
                            .tag(mood)
                        }
                    }
                    .pickerStyle(InlinePickerStyle())
                }
                
                Section(header: Text("日付と時刻")) {
                    DatePicker("記録日時", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                if !content.isEmpty {
                    Section(header: Text("プレビュー")) {
                        AsaCard(backgroundColor: Color(selectedCategory.color).opacity(0.1)) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack {
                                    Text(selectedCategory.emoji)
                                        .font(.title2)
                                    Text(selectedMood.emoji)
                                        .font(.caption)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(content)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        Text(selectedCategory.displayName)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color(selectedCategory.color).opacity(0.2))
                                            .foregroundColor(Color(selectedCategory.color))
                                            .cornerRadius(8)
                                        
                                        Text(selectedMood.stars)
                                            .font(.caption)
                                        
                                        Spacer()
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("感謝を記録")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveGratitude()
                }
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func saveGratitude() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        let newEntry = GratitudeEntry(
            date: selectedDate,
            content: trimmedContent,
            category: selectedCategory,
            moodLevel: selectedMood
        )
        
        viewModel.addGratitudeEntry(newEntry)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddGratitudeView(viewModel: GratitudeViewModel())
}