//
//  Comment.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import Foundation
import SwiftData

@Model
final class Comment: Identifiable {
    var id: UUID
    var text: String
    var author: String
    var createdAt: Date
    var updatedAt: Date
    var isEdited: Bool
    
    // Swift Dataリレーション
    var photo: Photo?
    
    init(
        text: String,
        author: String
    ) {
        self.id = UUID()
        self.text = text
        self.author = author
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isEdited = false
    }
    
    // MARK: - Computed Properties
    
    var displayText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        
        // 今日のコメントは時刻のみ
        if Calendar.current.isDateInToday(createdAt) {
            formatter.timeStyle = .short
        } else if Calendar.current.isDateInYesterday(createdAt) {
            return "昨日"
        } else {
            formatter.dateStyle = .short
        }
        
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }
    
    var timeAgo: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)
        
        if timeInterval < 60 {
            return "たった今"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)時間前"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)日前"
        }
    }
    
    var editStatus: String {
        if isEdited {
            return "(編集済み)"
        } else {
            return ""
        }
    }
    
    // MARK: - Methods
    
    func updateText(_ newText: String) {
        guard newText != text else { return }
        
        self.text = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.updatedAt = Date()
        self.isEdited = true
    }
    
    func canEdit(by currentUser: String) -> Bool {
        return author == currentUser
    }
    
    func isRecent() -> Bool {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return createdAt > oneHourAgo
    }
}

// MARK: - Sample Data

extension Comment {
    static func createSampleComment() -> Comment {
        let comments = [
            "素晴らしい写真ですね！",
            "この日のことを思い出します。",
            "家族での素敵な時間でした。",
            "また行きたいです！",
            "お気に入りの一枚です。"
        ]
        
        let authors = ["お父さん", "お母さん", "ひとし", "みゆき"]
        
        return Comment(
            text: comments.randomElement() ?? "素晴らしい写真ですね！",
            author: authors.randomElement() ?? "家族"
        )
    }
    
    static let sampleComments: [Comment] = [
        Comment(text: "素晴らしい日でした！", author: "お父さん"),
        Comment(text: "みんなで楽しめましたね。", author: "お母さん"),
        Comment(text: "この写真が一番お気に入りです。", author: "ひとし"),
    ]
}