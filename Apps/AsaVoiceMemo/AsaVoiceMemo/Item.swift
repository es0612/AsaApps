//
//  VoiceMemo.swift
//  AsaVoiceMemo
//  
//  Created on 2025/07/28
//

import Foundation
import SwiftData

@Model
final class VoiceMemo {
    var id: UUID
    var title: String
    var fileURL: URL
    var duration: TimeInterval
    var createdAt: Date
    var updatedAt: Date
    
    init(
        title: String,
        fileURL: URL,
        duration: TimeInterval = 0
    ) {
        self.id = UUID()
        self.title = title
        self.fileURL = fileURL
        self.duration = duration
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // フォーマットされた継続時間を取得
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // 相対的な作成日時を取得
    var relativeCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    // ファイルが存在するかチェック
    var fileExists: Bool {
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}
