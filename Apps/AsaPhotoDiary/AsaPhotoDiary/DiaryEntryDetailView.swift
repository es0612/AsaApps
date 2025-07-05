//
//  DiaryEntryDetailView.swift
//  AsaPhotoDiary
//  
//  Created on 2025/07/05
//

import SwiftUI

struct DiaryEntryDetailView: View {
    let entry: DiaryEntry
    @ObservedObject var viewModel: PhotoDiaryViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var isShowingEditView = false
    @State private var isShowingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 写真セクション
                if let image = entry.image {
                    VStack(spacing: 12) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(radius: 4)
                    }
                    .padding(.horizontal)
                }
                
                // タイトルと日付セクション
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title ?? "無題")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            Text(entry.dateFormatted)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(entry.timeFormatted)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if entry.updatedAt != entry.createdAt {
                                Text("編集済み")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // カテゴリーと気分セクション
                HStack(spacing: 12) {
                    // カテゴリー
                    HStack(spacing: 8) {
                        Text(entry.categoryEnum.emoji)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("カテゴリー")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(entry.categoryEnum.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(entry.categoryEnum.color))
                        }
                    }
                    .padding()
                    .background(Color(entry.categoryEnum.color).opacity(0.1))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    
                    Spacer()
                    
                    // 気分
                    HStack(spacing: 8) {
                        Text(entry.moodEnum.emoji)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("気分")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(entry.moodEnum.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(entry.moodEnum.color))
                        }
                    }
                    .padding()
                    .background(Color(entry.moodEnum.color).opacity(0.1))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                }
                .padding(.horizontal)
                
                // 内容セクション
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        Text("内容")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    
                    Text(entry.content ?? "")
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundColor(Color("AsaDarkSlate"))
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // アクションボタンセクション
                VStack(spacing: 12) {
                    Button(action: {
                        isShowingEditView = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.title2)
                            Text("編集")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("AsaCoffeeBrown"))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    Button(action: {
                        isShowingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.title2)
                            Text("削除")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("AsaMutedSage"))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .background(Color("AsaSoftCream").opacity(0.3))
        .navigationTitle("日記詳細")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingEditView) {
            AddEntryView(viewModel: viewModel, editingEntry: entry)
        }
        .alert("日記を削除", isPresented: $isShowingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                viewModel.deleteEntry(entry)
                dismiss()
            }
        } message: {
            Text("この日記を削除しますか？この操作は取り消せません。")
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let entry = DiaryEntry(context: context)
    entry.id = UUID()
    entry.title = "朝活で散歩"
    entry.content = "今日も早起きして近所の公園を散歩しました。朝の空気がとても気持ちよく、鳥のさえずりが聞こえて心が癒されました。桜の花びらが舞い散る様子がとても美しかったです。"
    entry.date = Date()
    entry.category = "日常"
    entry.mood = "とても良い"
    entry.createdAt = Date()
    entry.updatedAt = Date()
    
    return NavigationView {
        DiaryEntryDetailView(
            entry: entry,
            viewModel: PhotoDiaryViewModel(viewContext: context)
        )
    }
}