//
//  MultiTimerTests.swift
//  AsaTimerProTests
//
//  Created on 2025/09/05
//

import Testing
import Foundation
@testable import AsaTimerPro

struct MultiTimerTests {
    
    // MARK: - 初期化テスト
    
    @Test("MultiTimer初期化テスト")
    func testMultiTimerInitialization() {
        let multiTimer = MultiTimer()
        
        #expect(multiTimer.sessions.isEmpty)
        #expect(multiTimer.maxConcurrentTimers == 4)
        #expect(multiTimer.activeTimers.isEmpty)
        #expect(multiTimer.pendingTimers.isEmpty)
        #expect(multiTimer.completedTimers.isEmpty)
        #expect(multiTimer.canStartNewTimer == true)
    }
    
    @Test("MultiTimer最大同時実行数設定テスト")
    func testMultiTimerWithCustomMaxConcurrent() {
        let multiTimer = MultiTimer(maxConcurrentTimers: 2)
        
        #expect(multiTimer.maxConcurrentTimers == 2)
    }
    
    // MARK: - タイマー追加・削除テスト
    
    @Test("タイマー追加テスト")
    func testAddTimer() {
        var multiTimer = MultiTimer()
        let session = TimerSession(
            name: "テストタイマー1",
            category: .work,
            duration: 1800
        )
        
        multiTimer.addTimer(session)
        
        #expect(multiTimer.sessions.count == 1)
        #expect(multiTimer.sessions.first?.name == "テストタイマー1")
        #expect(multiTimer.pendingTimers.count == 1)
    }
    
    @Test("タイマー削除テスト")
    func testRemoveTimer() {
        var multiTimer = MultiTimer()
        let session = TimerSession(
            name: "削除テスト",
            category: .general,
            duration: 1800
        )
        
        multiTimer.addTimer(session)
        #expect(multiTimer.sessions.count == 1)
        
        multiTimer.removeTimer(with: session.id)
        #expect(multiTimer.sessions.count == 0)
    }
    
    @Test("タイマー更新テスト")
    func testUpdateTimer() {
        var multiTimer = MultiTimer()
        var session = TimerSession(
            name: "更新テスト",
            category: .general,
            duration: 1800
        )
        
        multiTimer.addTimer(session)
        
        // セッションを更新
        session.currentTime = 600
        session.state = .running
        multiTimer.updateTimer(session)
        
        let updatedSession = multiTimer.getTimer(with: session.id)
        #expect(updatedSession?.currentTime == 600)
        #expect(updatedSession?.state == .running)
    }
    
    // MARK: - フィルタリングテスト
    
    @Test("アクティブタイマーフィルタリングテスト")
    func testActiveTimersFiltering() {
        var multiTimer = MultiTimer()
        
        // 各状態のタイマーを追加
        let runningSession = TimerSession(
            name: "実行中",
            category: .work,
            duration: 1800,
            state: .running
        )
        let pausedSession = TimerSession(
            name: "一時停止",
            category: .work,
            duration: 1800,
            state: .paused
        )
        let completedSession = TimerSession(
            name: "完了済み",
            category: .work,
            duration: 1800,
            state: .completed
        )
        
        multiTimer.addTimer(runningSession)
        multiTimer.addTimer(pausedSession)
        multiTimer.addTimer(completedSession)
        
        #expect(multiTimer.activeTimers.count == 1)
        #expect(multiTimer.activeTimers.first?.name == "実行中")
        #expect(multiTimer.pausedTimers.count == 1)
        #expect(multiTimer.pausedTimers.first?.name == "一時停止")
        #expect(multiTimer.completedTimers.count == 1)
        #expect(multiTimer.completedTimers.first?.name == "完了済み")
    }
    
    @Test("カテゴリ別フィルタリングテスト")
    func testGetTimersForCategory() {
        var multiTimer = MultiTimer()
        
        let workSession = TimerSession(name: "仕事", category: .work, duration: 1800)
        let studySession = TimerSession(name: "勉強", category: .study, duration: 1800)
        let workSession2 = TimerSession(name: "仕事2", category: .work, duration: 1800)
        
        multiTimer.addTimer(workSession)
        multiTimer.addTimer(studySession)
        multiTimer.addTimer(workSession2)
        
        let workTimers = multiTimer.getTimers(for: .work)
        let studyTimers = multiTimer.getTimers(for: .study)
        
        #expect(workTimers.count == 2)
        #expect(studyTimers.count == 1)
        #expect(studyTimers.first?.name == "勉強")
    }
    
    @Test("カテゴリ別グループ化テスト")
    func testTimersByCategory() {
        var multiTimer = MultiTimer()
        
        let workSession = TimerSession(name: "仕事", category: .work, duration: 1800)
        let studySession = TimerSession(name: "勉強", category: .study, duration: 1800)
        let exerciseSession = TimerSession(name: "運動", category: .exercise, duration: 1800)
        
        multiTimer.addTimer(workSession)
        multiTimer.addTimer(studySession)
        multiTimer.addTimer(exerciseSession)
        
        let timersByCategory = multiTimer.timersByCategory
        
        #expect(timersByCategory[.work]?.count == 1)
        #expect(timersByCategory[.study]?.count == 1)
        #expect(timersByCategory[.exercise]?.count == 1)
        #expect(timersByCategory[.rest] == nil)
    }
    
    // MARK: - 同時実行制限テスト
    
    @Test("同時実行可能判定テスト")
    func testCanStartNewTimer() {
        var multiTimer = MultiTimer(maxConcurrentTimers: 2)
        
        // 実行中タイマーなし
        #expect(multiTimer.canStartNewTimer == true)
        
        // 1個実行中
        let session1 = TimerSession(name: "タイマー1", category: .work, duration: 1800, state: .running)
        multiTimer.addTimer(session1)
        #expect(multiTimer.canStartNewTimer == true)
        
        // 2個実行中（上限）
        let session2 = TimerSession(name: "タイマー2", category: .work, duration: 1800, state: .running)
        multiTimer.addTimer(session2)
        #expect(multiTimer.canStartNewTimer == false)
    }
    
    @Test("アクティブタイマー数カウントテスト")
    func testActiveTimerCount() {
        var multiTimer = MultiTimer()
        
        #expect(multiTimer.activeTimerCount == 0)
        
        let runningSession = TimerSession(name: "実行中", category: .work, duration: 1800, state: .running)
        let pausedSession = TimerSession(name: "一時停止", category: .work, duration: 1800, state: .paused)
        let completedSession = TimerSession(name: "完了", category: .work, duration: 1800, state: .completed)
        
        multiTimer.addTimer(runningSession)
        #expect(multiTimer.activeTimerCount == 1)
        
        multiTimer.addTimer(pausedSession)
        #expect(multiTimer.activeTimerCount == 1) // 一時停止はアクティブではない
        
        multiTimer.addTimer(completedSession)
        #expect(multiTimer.activeTimerCount == 1) // 完了はアクティブではない
    }
    
    // MARK: - 一括操作テスト
    
    @Test("全アクティブタイマー一時停止テスト")
    func testPauseAllActiveTimers() {
        var multiTimer = MultiTimer()
        
        let session1 = TimerSession(name: "タイマー1", category: .work, duration: 1800, state: .running)
        let session2 = TimerSession(name: "タイマー2", category: .study, duration: 1800, state: .running)
        let session3 = TimerSession(name: "タイマー3", category: .work, duration: 1800, state: .paused)
        
        multiTimer.addTimer(session1)
        multiTimer.addTimer(session2)
        multiTimer.addTimer(session3)
        
        #expect(multiTimer.activeTimers.count == 2)
        
        multiTimer.pauseAllActiveTimers()
        
        #expect(multiTimer.activeTimers.count == 0)
        #expect(multiTimer.pausedTimers.count == 3)
    }
    
    @Test("全タイマー停止テスト")
    func testStopAllTimers() {
        var multiTimer = MultiTimer()
        
        let session1 = TimerSession(name: "タイマー1", category: .work, duration: 1800, state: .running)
        let session2 = TimerSession(name: "タイマー2", category: .study, duration: 1800, state: .paused)
        
        multiTimer.addTimer(session1)
        multiTimer.addTimer(session2)
        
        multiTimer.stopAllTimers()
        
        for session in multiTimer.sessions {
            #expect(session.state == .cancelled)
        }
    }
    
    @Test("完了済みタイマー削除テスト")
    func testClearCompletedTimers() {
        var multiTimer = MultiTimer()
        
        let runningSession = TimerSession(name: "実行中", category: .work, duration: 1800, state: .running)
        let completedSession1 = TimerSession(name: "完了1", category: .work, duration: 1800, state: .completed)
        let completedSession2 = TimerSession(name: "完了2", category: .study, duration: 1800, state: .completed)
        
        multiTimer.addTimer(runningSession)
        multiTimer.addTimer(completedSession1)
        multiTimer.addTimer(completedSession2)
        
        #expect(multiTimer.sessions.count == 3)
        
        multiTimer.clearCompletedTimers()
        
        #expect(multiTimer.sessions.count == 1)
        #expect(multiTimer.sessions.first?.name == "実行中")
    }
    
    // MARK: - ソートテスト
    
    @Test("作成日時ソートテスト")
    func testSortedByCreated() async {
        var multiTimer = MultiTimer()
        
        let now = Date()
        let session1 = TimerSession(name: "新しい", category: .work, duration: 1800, createdAt: now)
        let session2 = TimerSession(name: "古い", category: .work, duration: 1800, createdAt: now.addingTimeInterval(-3600))
        
        multiTimer.addTimer(session2) // 古いものを先に追加
        multiTimer.addTimer(session1) // 新しいものを後に追加
        
        let sorted = multiTimer.sortedByCreated
        #expect(sorted.first?.name == "新しい") // 新しい順
        #expect(sorted.last?.name == "古い")
    }
    
    @Test("カテゴリソートテスト")
    func testSortedByCategory() {
        var multiTimer = MultiTimer()
        
        let studySession = TimerSession(name: "勉強", category: .study, duration: 1800)
        let workSession = TimerSession(name: "仕事", category: .work, duration: 1800)
        let generalSession = TimerSession(name: "一般", category: .general, duration: 1800)
        
        multiTimer.addTimer(studySession)
        multiTimer.addTimer(workSession)
        multiTimer.addTimer(generalSession)
        
        let sorted = multiTimer.sortedByCategory
        #expect(sorted[0].category == .general) // アルファベット順
        #expect(sorted[1].category == .study)
        #expect(sorted[2].category == .work)
    }
}