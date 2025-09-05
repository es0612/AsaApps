//
//  TimerStatsTests.swift
//  AsaTimerProTests
//
//  Created on 2025/09/05
//

import Testing
import Foundation
@testable import AsaTimerPro

struct TimerStatsTests {
    
    // MARK: - 空の統計テスト
    
    @Test("空のセッション統計テスト")
    func testEmptySessionStats() {
        let stats = TimerStats(sessions: [])
        
        #expect(stats.totalTimers == 0)
        #expect(stats.completedTimers == 0)
        #expect(stats.totalDuration == 0)
        #expect(stats.totalCompletedTime == 0)
        #expect(stats.averageDuration == 0.0)
        #expect(stats.completionRate == 0.0)
        #expect(stats.categoryBreakdown.isEmpty)
        #expect(stats.completionPercentage == 0)
    }
    
    // MARK: - 基本統計計算テスト
    
    @Test("基本統計計算テスト")
    func testBasicStatistics() {
        let sessions = [
            TimerSession(name: "完了1", category: .work, duration: 1800, state: .completed),
            TimerSession(name: "完了2", category: .study, duration: 3600, state: .completed),
            TimerSession(name: "未完了", category: .work, duration: 1200, state: .created)
        ]
        
        let stats = TimerStats(sessions: sessions)
        
        #expect(stats.totalTimers == 3)
        #expect(stats.completedTimers == 2)
        #expect(stats.totalDuration == 6600) // 1800 + 3600 + 1200
        #expect(stats.totalCompletedTime == 5400) // 1800 + 3600
        #expect(stats.averageDuration == 2200.0) // 6600 / 3
        #expect(stats.completionRate == (2.0 / 3.0))
        #expect(stats.completionPercentage == 66) // (2/3) * 100の整数部
    }
    
    @Test("完了率計算テスト")
    func testCompletionRateCalculation() {
        // 全て完了
        let allCompletedSessions = [
            TimerSession(name: "完了1", category: .work, duration: 1800, state: .completed),
            TimerSession(name: "完了2", category: .study, duration: 1800, state: .completed)
        ]
        let allCompletedStats = TimerStats(sessions: allCompletedSessions)
        #expect(allCompletedStats.completionRate == 1.0)
        #expect(allCompletedStats.completionPercentage == 100)
        
        // 全て未完了
        let noCompletedSessions = [
            TimerSession(name: "未完了1", category: .work, duration: 1800, state: .created),
            TimerSession(name: "未完了2", category: .study, duration: 1800, state: .running)
        ]
        let noCompletedStats = TimerStats(sessions: noCompletedSessions)
        #expect(noCompletedStats.completionRate == 0.0)
        #expect(noCompletedStats.completionPercentage == 0)
    }
    
    // MARK: - カテゴリ別集計テスト
    
    @Test("カテゴリ別集計テスト")
    func testCategoryBreakdown() {
        let sessions = [
            TimerSession(name: "仕事1", category: .work, duration: 1800),
            TimerSession(name: "仕事2", category: .work, duration: 1800),
            TimerSession(name: "仕事3", category: .work, duration: 1800),
            TimerSession(name: "勉強1", category: .study, duration: 1800),
            TimerSession(name: "勉強2", category: .study, duration: 1800),
            TimerSession(name: "運動1", category: .exercise, duration: 1800),
            TimerSession(name: "一般1", category: .general, duration: 1800)
        ]
        
        let stats = TimerStats(sessions: sessions)
        
        #expect(stats.categoryBreakdown[.work] == 3)
        #expect(stats.categoryBreakdown[.study] == 2)
        #expect(stats.categoryBreakdown[.exercise] == 1)
        #expect(stats.categoryBreakdown[.general] == 1)
        #expect(stats.categoryBreakdown[.rest] == nil) // 未使用のカテゴリ
        #expect(stats.categoryBreakdown[.cooking] == nil) // 未使用のカテゴリ
    }
    
    @Test("混在カテゴリ集計テスト")
    func testMixedCategoryBreakdown() {
        let sessions = [
            TimerSession(name: "仕事", category: .work, duration: 1800),
            TimerSession(name: "勉強", category: .study, duration: 1800),
            TimerSession(name: "料理", category: .cooking, duration: 1800),
            TimerSession(name: "仕事2", category: .work, duration: 1800),
            TimerSession(name: "休憩", category: .rest, duration: 1800),
            TimerSession(name: "運動", category: .exercise, duration: 1800),
            TimerSession(name: "勉強2", category: .study, duration: 1800)
        ]
        
        let stats = TimerStats(sessions: sessions)
        
        // 各カテゴリの数を検証
        let totalCounted = stats.categoryBreakdown.values.reduce(0, +)
        #expect(totalCounted == sessions.count)
        
        #expect(stats.categoryBreakdown[.work] == 2)
        #expect(stats.categoryBreakdown[.study] == 2)
        #expect(stats.categoryBreakdown[.cooking] == 1)
        #expect(stats.categoryBreakdown[.rest] == 1)
        #expect(stats.categoryBreakdown[.exercise] == 1)
    }
    
    // MARK: - 時間フォーマットテスト
    
    @Test("時間フォーマットテスト")
    func testTimeFormatting() {
        let sessions = [
            TimerSession(name: "短時間", category: .work, duration: 3665, state: .completed), // 1時間1分5秒
            TimerSession(name: "長時間", category: .work, duration: 7265, state: .completed)  // 2時間1分5秒
        ]
        
        let stats = TimerStats(sessions: sessions)
        
        // 総時間: 3665 + 7265 = 10930秒 = 3時間2分10秒
        #expect(stats.formattedTotalDuration == "03:02:00") // 秒は切り捨て
        
        // 完了時間: 同じく10930秒（全て完了済み）
        #expect(stats.formattedCompletedTime == "03:02:00")
    }
    
    @Test("異なる完了状態での時間フォーマットテスト")
    func testTimeFormattingWithMixedStates() {
        let sessions = [
            TimerSession(name: "完了", category: .work, duration: 3600, state: .completed), // 1時間完了
            TimerSession(name: "未完了", category: .work, duration: 1800, state: .created)    // 30分未完了
        ]
        
        let stats = TimerStats(sessions: sessions)
        
        // 総時間: 3600 + 1800 = 5400秒 = 1時間30分
        #expect(stats.formattedTotalDuration == "01:30:00")
        
        // 完了時間: 3600秒 = 1時間
        #expect(stats.formattedCompletedTime == "01:00:00")
    }
    
    // MARK: - エッジケーステスト
    
    @Test("単一セッション統計テスト")
    func testSingleSessionStats() {
        let sessions = [
            TimerSession(name: "単独", category: .work, duration: 1800, state: .completed)
        ]
        
        let stats = TimerStats(sessions: sessions)
        
        #expect(stats.totalTimers == 1)
        #expect(stats.completedTimers == 1)
        #expect(stats.totalDuration == 1800)
        #expect(stats.totalCompletedTime == 1800)
        #expect(stats.averageDuration == 1800.0)
        #expect(stats.completionRate == 1.0)
        #expect(stats.categoryBreakdown[.work] == 1)
    }
    
    @Test("様々な状態の統計テスト")
    func testVariousStatesStats() {
        let sessions = [
            TimerSession(name: "作成済み", category: .work, duration: 1800, state: .created),
            TimerSession(name: "実行中", category: .work, duration: 1800, state: .running),
            TimerSession(name: "一時停止", category: .work, duration: 1800, state: .paused),
            TimerSession(name: "完了", category: .work, duration: 1800, state: .completed),
            TimerSession(name: "キャンセル", category: .work, duration: 1800, state: .cancelled)
        ]
        
        let stats = TimerStats(sessions: sessions)
        
        #expect(stats.totalTimers == 5)
        #expect(stats.completedTimers == 1) // 完了状態のみ
        #expect(stats.completionRate == 0.2) // 1/5
        #expect(stats.completionPercentage == 20)
    }
}