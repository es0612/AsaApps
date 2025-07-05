//
//  DiaryEntryRowView.swift
//  AsaPhotoDiary
//  
//  Created on 2025/07/05
//

import SwiftUI

struct DiaryEntryRowView: View {
    let entry: DiaryEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // 写真表示エリア
            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // テキスト内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.title ?? "無題")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(entry.dateFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(entry.shortContent)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    // カテゴリー
                    HStack(spacing: 4) {
                        Text(entry.categoryEnum.emoji)
                            .font(.caption)
                        Text(entry.categoryEnum.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(entry.categoryEnum.color).opacity(0.2))
                    .foregroundColor(Color(entry.categoryEnum.color))
                    .cornerRadius(6)
                    
                    // 気分
                    HStack(spacing: 4) {
                        Text(entry.moodEnum.emoji)
                            .font(.caption)
                        Text(entry.moodEnum.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(entry.moodEnum.color).opacity(0.2))
                    .foregroundColor(Color(entry.moodEnum.color))
                    .cornerRadius(6)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let entry = DiaryEntry(context: context)
    entry.id = UUID()
    entry.title = "サンプル日記"
    entry.content = "これはサンプルの日記です。長い文章でもちゃんと表示されるかテストしています。"
    entry.date = Date()
    entry.category = "日常"
    entry.mood = "良い"
    entry.createdAt = Date()
    entry.updatedAt = Date()
    
    return DiaryEntryRowView(entry: entry)
        .padding()
        .background(Color("AsaSoftCream"))
}