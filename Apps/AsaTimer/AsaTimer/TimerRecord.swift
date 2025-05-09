//
//  TimerRecord.swift
//  AsaTimer
//  
//  Created on 2025/05/09
//


import Foundation

struct TimerRecord: Identifiable {
    let id = UUID()
    let duration: Int // タイマー時間（秒）
    let endTime: Date // タイマー終了時刻

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
