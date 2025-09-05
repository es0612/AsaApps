//
//  TimerSession.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import Foundation

// タイマーの実行状態
enum TimerState: String, Codable {
    case created = "created"       // 作成済み（未開始）
    case running = "running"       // 実行中
    case paused = "paused"         // 一時停止
    case completed = "completed"   // 完了
    case cancelled = "cancelled"   // キャンセル済み
}

// 個別のタイマーセッション（TimerRecordを拡張）
struct TimerSession: Identifiable, Codable, Sendable {
    let id: UUID
    let name: String                    // タイマー名
    let category: TimerCategory         // カテゴリ
    let duration: Int                   // 設定時間（秒）
    var currentTime: Int                // 現在の経過時間（秒）
    var state: TimerState               // 実行状態
    let createdAt: Date                 // 作成日時
    var startTime: Date?                // 開始時刻
    var endTime: Date?                  // 終了時刻
    var pausedAt: Date?                 // 一時停止時刻
    var resumedAt: Date?                // 再開時刻
    var memo: String?                   // メモ（オプション）
    var repeatCount: Int                // 繰り返し回数
    var isRepeating: Bool               // 繰り返し設定
    
    // MARK: - Init
    init(
        id: UUID = UUID(),
        name: String,
        category: TimerCategory = .general,
        duration: Int,
        currentTime: Int = 0,
        state: TimerState = .created,
        createdAt: Date = Date(),
        startTime: Date? = nil,
        endTime: Date? = nil,
        pausedAt: Date? = nil,
        resumedAt: Date? = nil,
        memo: String? = nil,
        repeatCount: Int = 1,
        isRepeating: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.duration = duration
        self.currentTime = currentTime
        self.state = state
        self.createdAt = createdAt
        self.startTime = startTime
        self.endTime = endTime
        self.pausedAt = pausedAt
        self.resumedAt = resumedAt
        self.memo = memo
        self.repeatCount = repeatCount
        self.isRepeating = isRepeating
    }
    
    // MARK: - Computed Properties
    
    // 残り時間（秒）
    var remainingTime: Int {
        return max(0, duration - currentTime)
    }
    
    // プログレス（0.0～1.0）
    var progress: Double {
        guard duration > 0 else { return 0.0 }
        return min(1.0, Double(currentTime) / Double(duration))
    }
    
    // フォーマット済みの設定時間（MM:SS）
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    // フォーマット済みの現在時間（MM:SS）
    var formattedCurrentTime: String {
        return formatTime(currentTime)
    }
    
    // フォーマット済みの残り時間（MM:SS）
    var formattedRemainingTime: String {
        return formatTime(remainingTime)
    }
    
    // 作成時刻をフォーマット（例: 2025-09-05 10:30:45）
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: createdAt)
    }
    
    // タイマーが完了しているか
    var isCompleted: Bool {
        return state == .completed || currentTime >= duration
    }
    
    // タイマーがアクティブ（実行中）か
    var isActive: Bool {
        return state == .running
    }
    
    // タイマーが一時停止中か
    var isPaused: Bool {
        return state == .paused
    }
    
    // MARK: - Methods
    
    // 時間をフォーマット（MM:SS形式）
    private func formatTime(_ timeInSeconds: Int) -> String {
        let minutes = timeInSeconds / 60
        let seconds = timeInSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // タイマーを開始
    mutating func start() {
        guard state == .created || state == .paused else { return }
        
        state = .running
        if startTime == nil {
            startTime = Date()
        }
        if state == .paused {
            resumedAt = Date()
        }
        pausedAt = nil
    }
    
    // タイマーを一時停止
    mutating func pause() {
        guard state == .running else { return }
        
        state = .paused
        pausedAt = Date()
    }
    
    // タイマーを停止（リセット）
    mutating func stop() {
        state = .cancelled
        endTime = Date()
        currentTime = 0
    }
    
    // タイマーを完了
    mutating func complete() {
        state = .completed
        endTime = Date()
        currentTime = duration
    }
    
    // 時間を1秒進める
    mutating func tick() {
        guard state == .running else { return }
        
        currentTime += 1
        
        // 時間に達したら完了
        if currentTime >= duration {
            complete()
        }
    }
    
    // タイマーをリセット（繰り返し用）
    mutating func reset() {
        currentTime = 0
        state = .created
        startTime = nil
        endTime = nil
        pausedAt = nil
        resumedAt = nil
        if isRepeating {
            repeatCount += 1
        }
    }
}