//
//  MultiTimer.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import Foundation

// 複数タイマー管理モデル
struct MultiTimer: Codable, Sendable {
    private(set) var sessions: [TimerSession]
    private(set) var maxConcurrentTimers: Int
    
    // MARK: - Init
    init(maxConcurrentTimers: Int = 4) {
        self.sessions = []
        self.maxConcurrentTimers = maxConcurrentTimers
    }
    
    // MARK: - Computed Properties
    
    // アクティブ（実行中）のタイマー一覧
    var activeTimers: [TimerSession] {
        return sessions.filter { $0.isActive }
    }
    
    // 一時停止中のタイマー一覧
    var pausedTimers: [TimerSession] {
        return sessions.filter { $0.isPaused }
    }
    
    // 完了済みのタイマー一覧
    var completedTimers: [TimerSession] {
        return sessions.filter { $0.isCompleted }
    }
    
    // 作成済み（未開始）のタイマー一覧
    var pendingTimers: [TimerSession] {
        return sessions.filter { $0.state == .created }
    }
    
    // カテゴリ別にグループ化されたタイマー
    var timersByCategory: [TimerCategory: [TimerSession]] {
        return Dictionary(grouping: sessions) { $0.category }
    }
    
    // アクティブタイマーの数
    var activeTimerCount: Int {
        return activeTimers.count
    }
    
    // 同時実行可能か
    var canStartNewTimer: Bool {
        return activeTimerCount < maxConcurrentTimers
    }
    
    // 本日のタイマー統計
    var todayStats: TimerStats {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTimers = sessions.filter { 
            Calendar.current.isDate($0.createdAt, inSameDayAs: today) 
        }
        return TimerStats(sessions: todayTimers)
    }
    
    // 全期間のタイマー統計
    var overallStats: TimerStats {
        return TimerStats(sessions: sessions)
    }
    
    // MARK: - Methods
    
    // タイマーを追加
    mutating func addTimer(_ session: TimerSession) {
        sessions.append(session)
    }
    
    // タイマーを削除
    mutating func removeTimer(with id: UUID) {
        sessions.removeAll { $0.id == id }
    }
    
    // タイマーを更新
    mutating func updateTimer(_ updatedSession: TimerSession) {
        if let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) {
            sessions[index] = updatedSession
        }
    }
    
    // 指定したIDのタイマーを取得
    func getTimer(with id: UUID) -> TimerSession? {
        return sessions.first { $0.id == id }
    }
    
    // 指定したカテゴリのタイマーを取得
    func getTimers(for category: TimerCategory) -> [TimerSession] {
        return sessions.filter { $0.category == category }
    }
    
    // 全てのアクティブタイマーを一時停止
    mutating func pauseAllActiveTimers() {
        for index in sessions.indices {
            if sessions[index].isActive {
                sessions[index].pause()
            }
        }
    }
    
    // 全てのタイマーを停止
    mutating func stopAllTimers() {
        for index in sessions.indices {
            sessions[index].stop()
        }
    }
    
    // 完了済みタイマーを削除
    mutating func clearCompletedTimers() {
        sessions.removeAll { $0.isCompleted }
    }
    
    // 全てのタイマーをクリア
    mutating func clearAllTimers() {
        sessions.removeAll()
    }
    
    // 指定した期間のタイマーを取得
    func getTimers(from startDate: Date, to endDate: Date) -> [TimerSession] {
        return sessions.filter { session in
            session.createdAt >= startDate && session.createdAt <= endDate
        }
    }
    
    // タイマーを時間順にソート
    var sortedByCreated: [TimerSession] {
        return sessions.sorted { $0.createdAt > $1.createdAt }
    }
    
    // タイマーをカテゴリ順にソート
    var sortedByCategory: [TimerSession] {
        return sessions.sorted { $0.category.displayName < $1.category.displayName }
    }
}

// タイマー統計情報
struct TimerStats: Codable {
    let totalTimers: Int
    let completedTimers: Int
    let totalDuration: Int          // 総設定時間（秒）
    let totalCompletedTime: Int     // 総完了時間（秒）
    let averageDuration: Double     // 平均設定時間（秒）
    let completionRate: Double      // 完了率（0.0～1.0）
    let categoryBreakdown: [TimerCategory: Int]  // カテゴリ別カウント
    
    init(sessions: [TimerSession]) {
        self.totalTimers = sessions.count
        self.completedTimers = sessions.filter { $0.isCompleted }.count
        self.totalDuration = sessions.reduce(0) { $0 + $1.duration }
        self.totalCompletedTime = sessions.filter { $0.isCompleted }.reduce(0) { $0 + $1.duration }
        
        if totalTimers > 0 {
            self.averageDuration = Double(totalDuration) / Double(totalTimers)
            self.completionRate = Double(completedTimers) / Double(totalTimers)
        } else {
            self.averageDuration = 0.0
            self.completionRate = 0.0
        }
        
        // カテゴリ別の集計
        var breakdown: [TimerCategory: Int] = [:]
        for session in sessions {
            breakdown[session.category, default: 0] += 1
        }
        self.categoryBreakdown = breakdown
    }
    
    // フォーマット済み総時間
    var formattedTotalDuration: String {
        let hours = totalDuration / 3600
        let minutes = (totalDuration % 3600) / 60
        return String(format: "%02d:%02d:00", hours, minutes)
    }
    
    // フォーマット済み完了時間
    var formattedCompletedTime: String {
        let hours = totalCompletedTime / 3600
        let minutes = (totalCompletedTime % 3600) / 60
        return String(format: "%02d:%02d:00", hours, minutes)
    }
    
    // 完了率（パーセント）
    var completionPercentage: Int {
        return Int(completionRate * 100)
    }
}