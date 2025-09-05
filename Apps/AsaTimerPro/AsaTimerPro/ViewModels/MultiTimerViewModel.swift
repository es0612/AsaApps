//
//  MultiTimerViewModel.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import Foundation
import SwiftUI
import AVFoundation

@Observable
final class MultiTimerViewModel {
    // MARK: - Properties
    private(set) var multiTimer: MultiTimer
    private var timers: [UUID: Timer] = [:]  // アクティブなFoundation.Timer
    private var audioPlayer: AVAudioPlayer?
    
    // UI状態管理
    var isLoading: Bool = false
    var errorMessage: String?
    var showErrorAlert: Bool = false
    
    // フィルター・ソート設定
    var selectedCategory: TimerCategory? = nil
    var sortOption: SortOption = .createdDate
    var showCompletedTimers: Bool = true
    
    // 設定
    var playSounds: Bool = true {
        didSet {
            UserDefaults.standard.set(playSounds, forKey: "AsaTimerPro.playSounds")
        }
    }
    
    var maxConcurrentTimers: Int = 4 {
        didSet {
            UserDefaults.standard.set(maxConcurrentTimers, forKey: "AsaTimerPro.maxConcurrentTimers")
        }
    }
    
    // MARK: - Computed Properties
    
    // フィルター済みタイマーリスト
    var filteredTimers: [TimerSession] {
        var timers = multiTimer.sessions
        
        // カテゴリフィルター
        if let category = selectedCategory {
            timers = timers.filter { $0.category == category }
        }
        
        // 完了済みタイマーの表示/非表示
        if !showCompletedTimers {
            timers = timers.filter { !$0.isCompleted }
        }
        
        // ソート
        switch sortOption {
        case .createdDate:
            timers.sort { $0.createdAt > $1.createdAt }
        case .name:
            timers.sort { $0.name < $1.name }
        case .category:
            timers.sort { $0.category.displayName < $1.category.displayName }
        case .duration:
            timers.sort { $0.duration > $1.duration }
        case .status:
            timers.sort { $0.state.rawValue < $1.state.rawValue }
        }
        
        return timers
    }
    
    // アクティブタイマー
    var activeTimers: [TimerSession] {
        return multiTimer.activeTimers
    }
    
    // 今日の統計
    var todayStats: TimerStats {
        return multiTimer.todayStats
    }
    
    // 新しいタイマーを開始できるか
    var canStartNewTimer: Bool {
        return multiTimer.canStartNewTimer
    }
    
    // MARK: - Init
    init() {
        self.multiTimer = MultiTimer()
        self.setupAudioPlayer()
        self.loadSettings()
        self.loadTimersFromStorage()
    }
    
    deinit {
        stopAllTimers()
    }
    
    // MARK: - Public Methods
    
    // タイマーを追加
    func addTimer(
        name: String,
        category: TimerCategory,
        duration: Int,
        memo: String? = nil,
        isRepeating: Bool = false
    ) {
        let session = TimerSession(
            name: name,
            category: category,
            duration: duration,
            memo: memo,
            isRepeating: isRepeating
        )
        
        multiTimer.addTimer(session)
        saveTimersToStorage()
    }
    
    // タイマーを開始
    func startTimer(with id: UUID) {
        guard canStartNewTimer else {
            showError("同時実行可能なタイマー数の上限に達しています")
            return
        }
        
        guard let index = multiTimer.sessions.firstIndex(where: { $0.id == id }) else {
            showError("タイマーが見つかりません")
            return
        }
        
        multiTimer.sessions[index].start()
        startFoundationTimer(for: id)
        saveTimersToStorage()
    }
    
    // タイマーを一時停止
    func pauseTimer(with id: UUID) {
        guard let index = multiTimer.sessions.firstIndex(where: { $0.id == id }) else { return }
        
        multiTimer.sessions[index].pause()
        stopFoundationTimer(for: id)
        saveTimersToStorage()
    }
    
    // タイマーを停止
    func stopTimer(with id: UUID) {
        guard let index = multiTimer.sessions.firstIndex(where: { $0.id == id }) else { return }
        
        multiTimer.sessions[index].stop()
        stopFoundationTimer(for: id)
        saveTimersToStorage()
    }
    
    // タイマーを削除
    func deleteTimer(with id: UUID) {
        stopFoundationTimer(for: id)
        multiTimer.removeTimer(with: id)
        saveTimersToStorage()
    }
    
    // 全タイマーを一時停止
    func pauseAllTimers() {
        multiTimer.pauseAllActiveTimers()
        stopAllFoundationTimers()
        saveTimersToStorage()
    }
    
    // 完了済みタイマーを削除
    func clearCompletedTimers() {
        multiTimer.clearCompletedTimers()
        saveTimersToStorage()
    }
    
    // タイマーを更新
    func updateTimer(_ updatedSession: TimerSession) {
        multiTimer.updateTimer(updatedSession)
        saveTimersToStorage()
    }
    
    // MARK: - Private Methods
    
    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "notification", withExtension: "mp3") else {
            print("通知サウンドファイルが見つかりません")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("オーディオプレイヤーの初期化に失敗: \(error)")
        }
    }
    
    private func loadSettings() {
        playSounds = UserDefaults.standard.bool(forKey: "AsaTimerPro.playSounds")
        maxConcurrentTimers = UserDefaults.standard.integer(forKey: "AsaTimerPro.maxConcurrentTimers")
        
        // デフォルト値の設定
        if maxConcurrentTimers == 0 {
            maxConcurrentTimers = 4
        }
    }
    
    private func startFoundationTimer(for sessionId: UUID) {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.handleTimerTick(for: sessionId)
        }
        
        timers[sessionId] = timer
    }
    
    private func stopFoundationTimer(for sessionId: UUID) {
        timers[sessionId]?.invalidate()
        timers.removeValue(forKey: sessionId)
    }
    
    private func stopAllFoundationTimers() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
    }
    
    private func stopAllTimers() {
        stopAllFoundationTimers()
        multiTimer.stopAllTimers()
    }
    
    private func handleTimerTick(for sessionId: UUID) {
        guard let index = multiTimer.sessions.firstIndex(where: { $0.id == sessionId }) else {
            stopFoundationTimer(for: sessionId)
            return
        }
        
        multiTimer.sessions[index].tick()
        
        let session = multiTimer.sessions[index]
        
        // タイマーが完了した場合
        if session.isCompleted {
            stopFoundationTimer(for: sessionId)
            handleTimerCompleted(session)
        }
    }
    
    private func handleTimerCompleted(_ session: TimerSession) {
        // サウンド再生
        if playSounds {
            audioPlayer?.play()
        }
        
        // 繰り返しタイマーの場合
        if session.isRepeating {
            if let index = multiTimer.sessions.firstIndex(where: { $0.id == session.id }) {
                multiTimer.sessions[index].reset()
                startFoundationTimer(for: session.id)
            }
        }
        
        saveTimersToStorage()
        
        // 通知（将来的にNotificationServiceで実装）
        print("タイマー「\(session.name)」が完了しました")
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    // MARK: - Data Persistence
    
    private func saveTimersToStorage() {
        // 将来的にTimerDataServiceで実装
        if let encoded = try? JSONEncoder().encode(multiTimer) {
            UserDefaults.standard.set(encoded, forKey: "AsaTimerPro.multiTimer")
        }
    }
    
    private func loadTimersFromStorage() {
        isLoading = true
        
        if let data = UserDefaults.standard.data(forKey: "AsaTimerPro.multiTimer"),
           let decoded = try? JSONDecoder().decode(MultiTimer.self, from: data) {
            self.multiTimer = decoded
            
            // 実行中だったタイマーがあれば再開（アプリクラッシュ対応）
            for session in multiTimer.activeTimers {
                startFoundationTimer(for: session.id)
            }
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Types

extension MultiTimerViewModel {
    enum SortOption: String, CaseIterable, Identifiable {
        case createdDate = "createdDate"
        case name = "name"
        case category = "category"
        case duration = "duration"
        case status = "status"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .createdDate:
                return "作成日時"
            case .name:
                return "名前"
            case .category:
                return "カテゴリ"
            case .duration:
                return "時間"
            case .status:
                return "状態"
            }
        }
    }
}