//
//  StepRecord.swift
//  AsaStepCounter
//  
//  Created on 2025/08/15
//

import Foundation
import SwiftData

@Model
final class StepRecord {
    /// 日付（時刻は00:00:00に正規化）
    @Attribute(.unique) var date: Date
    /// その日の歩数
    var stepCount: Int
    /// その日の目標歩数
    var dailyGoal: Int
    /// 目標達成フラグ
    var isGoalAchieved: Bool
    /// 記録の作成・更新日時
    var updatedAt: Date
    
    init(date: Date, stepCount: Int = 0, dailyGoal: Int = 10000) {
        // 日付を00:00:00に正規化
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.stepCount = stepCount
        self.dailyGoal = dailyGoal
        self.isGoalAchieved = stepCount >= dailyGoal
        self.updatedAt = Date()
    }
    
    /// 歩数を更新し、目標達成状況も更新
    func updateStepCount(_ newStepCount: Int) {
        stepCount = newStepCount
        isGoalAchieved = stepCount >= dailyGoal
        updatedAt = Date()
    }
    
    /// 目標歩数を更新し、達成状況も更新
    func updateDailyGoal(_ newGoal: Int) {
        dailyGoal = newGoal
        isGoalAchieved = stepCount >= dailyGoal
        updatedAt = Date()
    }
    
    /// 達成率を計算（0.0〜1.0、上限なし）
    var achievementRate: Double {
        guard dailyGoal > 0 else { return 0.0 }
        return Double(stepCount) / Double(dailyGoal)
    }
    
    /// 達成率をパーセントで取得（0〜100%、上限なし）
    var achievementPercentage: Int {
        return Int(achievementRate * 100)
    }
}
