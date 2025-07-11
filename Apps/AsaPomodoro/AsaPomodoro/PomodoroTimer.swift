//
//  PomodoroTimer.swift
//  AsaPomodoro
//  
//  Created on 2025/07/11
//

import Foundation
import SwiftUI

enum PomodoroMode {
    case work
    case shortBreak
    case longBreak
}

@Observable
class PomodoroTimer {
    
    // MARK: - Properties
    var currentMode: PomodoroMode = .work
    var isRunning: Bool = false
    var isPaused: Bool = false
    var remainingTime: TimeInterval = 25 * 60 // 25分
    var currentSet: Int = 1
    var completedSets: Int = 0
    
    // MARK: - Settings
    var workDuration: TimeInterval = 25 * 60 // 25分
    var shortBreakDuration: TimeInterval = 5 * 60 // 5分
    var longBreakDuration: TimeInterval = 15 * 60 // 15分
    var setsBeforeLongBreak: Int = 4
    
    // MARK: - Private
    private var timer: Timer?
    private var startTime: Date?
    private var totalDuration: TimeInterval = 25 * 60
    
    // MARK: - Computed Properties
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, (totalDuration - remainingTime) / totalDuration))
    }
    
    var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var modeDisplayText: String {
        switch currentMode {
        case .work:
            return "作業時間"
        case .shortBreak:
            return "短い休憩"
        case .longBreak:
            return "長い休憩"
        }
    }
    
    // MARK: - Timer Control
    func startTimer() {
        guard !isRunning else { return }
        
        isRunning = true
        isPaused = false
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func pauseTimer() {
        guard isRunning else { return }
        
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func resumeTimer() {
        guard isPaused else { return }
        startTimer()
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        
        switch currentMode {
        case .work:
            remainingTime = workDuration
            totalDuration = workDuration
        case .shortBreak:
            remainingTime = shortBreakDuration
            totalDuration = shortBreakDuration
        case .longBreak:
            remainingTime = longBreakDuration
            totalDuration = longBreakDuration
        }
    }
    
    func resetSession() {
        resetTimer()
        currentMode = .work
        currentSet = 1
        completedSets = 0
        remainingTime = workDuration
        totalDuration = workDuration
    }
    
    // MARK: - Private Methods
    private func updateTimer() {
        guard remainingTime > 0 else {
            completeCurrentSession()
            return
        }
        
        remainingTime -= 1
    }
    
    private func completeCurrentSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        
        switch currentMode {
        case .work:
            completedSets += 1
            
            if completedSets % setsBeforeLongBreak == 0 {
                // 長い休憩
                currentMode = .longBreak
                remainingTime = longBreakDuration
                totalDuration = longBreakDuration
            } else {
                // 短い休憩
                currentMode = .shortBreak
                remainingTime = shortBreakDuration
                totalDuration = shortBreakDuration
            }
            
        case .shortBreak, .longBreak:
            // 休憩後は作業に戻る
            currentMode = .work
            currentSet = completedSets + 1
            remainingTime = workDuration
            totalDuration = workDuration
        }
        
        // 通知の送信（後で実装）
        NotificationCenter.default.post(name: .pomodoroSessionCompleted, object: nil)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let pomodoroSessionCompleted = Notification.Name("pomodoroSessionCompleted")
}