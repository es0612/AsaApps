//
//  AsaHealthKit.swift
//  AsaHealthKit
//
//  健康・フィットネス関連アプリ向け共有ライブラリ
//  バージョン情報とライブラリ初期化
//

import Foundation

/// AsaHealthKit ライブラリのメインクラス
public struct AsaHealthKitLib {
    /// ライブラリバージョン
    public static let version = "1.0.0"
    
    /// デバッグモード（開発時のログ出力制御）
    nonisolated(unsafe) public static var debugMode: Bool = false
    
    /// ライブラリ名
    public static let name = "AsaHealthKit"
    
    /// 初期化（将来的な設定オプション用）
    private init() {}
}

/// AsaHealthKit で使用する共通定数
public struct HealthKitConstants {
    /// デフォルトの健康目標値
    public struct DefaultGoals {
        public static let dailySteps = 10000
        public static let dailyWaterML = 2000.0
        public static let dailySleepHours = 8.0
        public static let weeklyWorkoutMinutes = 150
    }
    
    /// 健康指標の単位
    public struct Units {
        public static let steps = "歩"
        public static let waterML = "ml"
        public static let sleepHours = "時間"
        public static let workoutMinutes = "分"
        public static let weight = "kg"
        public static let bodyFat = "%"
    }
    
    /// データ永続化キー
    public struct PersistenceKeys {
        public static let waterIntakes = "health_water_intakes"
        public static let sleepRecords = "health_sleep_records"
        public static let stepRecords = "health_step_records"
        public static let workoutRecords = "health_workout_records"
        public static let weightRecords = "health_weight_records"
        public static let moodRecords = "health_mood_records"
    }
}