//
//  TimerRecord.swift
//  AsaTimer
//
//  Created on 2025/05/09
//


import Foundation

struct TimerRecord: Identifiable,Codable {
    let id: UUID // タイマーのユニークID
    let duration: Int // タイマー時間（秒）
    let endTime: Date // タイマー終了時刻
    let repeatCount: Int // 繰り返し回数
    
    // 初期化
    init(id: UUID = UUID(), duration: Int, endTime: Date, repeatCount: Int = 1) {
        self.id = id
        self.duration = duration
        self.endTime = endTime
        self.repeatCount = repeatCount
    }
    // フォーマット済みの時間を返す（MM:SS）
    var formattedDuration: String {
        let minutes = duration / 60
        let remainingSeconds = duration % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // 終了時刻をフォーマット（例: 2025-05-09 05:30:45）
    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: endTime)
    }
}
