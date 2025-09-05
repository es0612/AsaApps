//
//  TimerSessionTests.swift
//  AsaTimerProTests
//
//  Created on 2025/09/05
//

import Testing
import Foundation
@testable import AsaTimerPro

struct TimerSessionTests {
    
    // MARK: - 初期化テスト
    
    @Test("TimerSession初期化テスト")
    func testTimerSessionInitialization() {
        let session = TimerSession(
            name: "テストタイマー",
            category: .work,
            duration: 1800
        )
        
        #expect(session.name == "テストタイマー")
        #expect(session.category == .work)
        #expect(session.duration == 1800)
        #expect(session.currentTime == 0)
        #expect(session.state == .created)
        #expect(session.repeatCount == 1)
        #expect(session.isRepeating == false)
    }
    
    @Test("TimerSession全パラメータ初期化テスト")
    func testTimerSessionFullInitialization() {
        let testDate = Date()
        let session = TimerSession(
            name: "完全テストタイマー",
            category: .study,
            duration: 3600,
            currentTime: 600,
            state: .running,
            createdAt: testDate,
            memo: "テストメモ",
            repeatCount: 3,
            isRepeating: true
        )
        
        #expect(session.name == "完全テストタイマー")
        #expect(session.category == .study)
        #expect(session.duration == 3600)
        #expect(session.currentTime == 600)
        #expect(session.state == .running)
        #expect(session.createdAt == testDate)
        #expect(session.memo == "テストメモ")
        #expect(session.repeatCount == 3)
        #expect(session.isRepeating == true)
    }
    
    // MARK: - 計算プロパティテスト
    
    @Test("残り時間計算テスト")
    func testRemainingTime() {
        var session = TimerSession(
            name: "計算テスト",
            category: .general,
            duration: 1800,
            currentTime: 600
        )
        
        #expect(session.remainingTime == 1200) // 1800 - 600
        
        // 進捗を進める
        session.currentTime = 1800
        #expect(session.remainingTime == 0)
        
        // オーバーしても0以下にならない
        session.currentTime = 2000
        #expect(session.remainingTime == 0)
    }
    
    @Test("プログレス計算テスト")
    func testProgress() {
        var session = TimerSession(
            name: "プログレステスト",
            category: .general,
            duration: 1000
        )
        
        #expect(session.progress == 0.0) // 開始時
        
        session.currentTime = 250
        #expect(session.progress == 0.25) // 25%
        
        session.currentTime = 500
        #expect(session.progress == 0.5) // 50%
        
        session.currentTime = 1000
        #expect(session.progress == 1.0) // 100%
        
        session.currentTime = 1200
        #expect(session.progress == 1.0) // 100%を超えない
    }
    
    @Test("時間フォーマットテスト")
    func testTimeFormatting() {
        let session = TimerSession(
            name: "フォーマットテスト",
            category: .general,
            duration: 3665, // 1時間1分5秒
            currentTime: 125 // 2分5秒
        )
        
        #expect(session.formattedDuration == "61:05")
        #expect(session.formattedCurrentTime == "02:05")
        #expect(session.formattedRemainingTime == "59:00")
    }
    
    // MARK: - 状態判定テスト
    
    @Test("状態判定プロパティテスト")
    func testStateProperties() {
        var session = TimerSession(
            name: "状態テスト",
            category: .general,
            duration: 1800
        )
        
        // 作成時
        #expect(session.isActive == false)
        #expect(session.isPaused == false)
        #expect(session.isCompleted == false)
        
        // 実行中
        session.state = .running
        #expect(session.isActive == true)
        #expect(session.isPaused == false)
        #expect(session.isCompleted == false)
        
        // 一時停止
        session.state = .paused
        #expect(session.isActive == false)
        #expect(session.isPaused == true)
        #expect(session.isCompleted == false)
        
        // 完了
        session.state = .completed
        #expect(session.isActive == false)
        #expect(session.isPaused == false)
        #expect(session.isCompleted == true)
    }
    
    // MARK: - 操作メソッドテスト
    
    @Test("タイマー開始テスト")
    func testTimerStart() {
        var session = TimerSession(
            name: "開始テスト",
            category: .general,
            duration: 1800
        )
        
        // 作成済み状態から開始
        session.start()
        #expect(session.state == .running)
        #expect(session.startTime != nil)
        
        // 一時停止状態から再開
        session.state = .paused
        session.start()
        #expect(session.state == .running)
        #expect(session.resumedAt != nil)
    }
    
    @Test("タイマー一時停止テスト")
    func testTimerPause() {
        var session = TimerSession(
            name: "一時停止テスト",
            category: .general,
            duration: 1800,
            state: .running
        )
        
        session.pause()
        #expect(session.state == .paused)
        #expect(session.pausedAt != nil)
    }
    
    @Test("タイマー停止テスト")
    func testTimerStop() {
        var session = TimerSession(
            name: "停止テスト",
            category: .general,
            duration: 1800,
            currentTime: 600,
            state: .running
        )
        
        session.stop()
        #expect(session.state == .cancelled)
        #expect(session.currentTime == 0)
        #expect(session.endTime != nil)
    }
    
    @Test("タイマー完了テスト")
    func testTimerComplete() {
        var session = TimerSession(
            name: "完了テスト",
            category: .general,
            duration: 1800,
            currentTime: 1700,
            state: .running
        )
        
        session.complete()
        #expect(session.state == .completed)
        #expect(session.currentTime == session.duration)
        #expect(session.endTime != nil)
    }
    
    @Test("タイマーtickテスト")
    func testTimerTick() {
        var session = TimerSession(
            name: "Tickテスト",
            category: .general,
            duration: 10,
            state: .running
        )
        
        // 通常のtick
        for i in 1...9 {
            session.tick()
            #expect(session.currentTime == i)
            #expect(session.state == .running)
        }
        
        // 完了に達するtick
        session.tick()
        #expect(session.currentTime == 10)
        #expect(session.state == .completed)
    }
    
    @Test("タイマーリセットテスト")
    func testTimerReset() {
        var session = TimerSession(
            name: "リセットテスト",
            category: .general,
            duration: 1800,
            currentTime: 600,
            state: .completed,
            repeatCount: 2,
            isRepeating: true
        )
        
        session.reset()
        #expect(session.currentTime == 0)
        #expect(session.state == .created)
        #expect(session.startTime == nil)
        #expect(session.endTime == nil)
        #expect(session.pausedAt == nil)
        #expect(session.resumedAt == nil)
        #expect(session.repeatCount == 3) // 繰り返しの場合はインクリメント
    }
}