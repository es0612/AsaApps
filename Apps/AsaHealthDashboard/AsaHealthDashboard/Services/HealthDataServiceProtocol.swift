//
//  HealthDataServiceProtocol.swift
//  AsaHealthDashboard
//
//  HealthKitサービスのプロトコル定義（テスト容易性のため）
//

import Foundation

/// HealthKitデータサービスのプロトコル
protocol HealthDataServiceProtocol: AnyObject {
    /// HealthKitが利用可能かどうか
    var isHealthKitAvailable: Bool { get }

    /// 権限が許可されているかどうか
    var isAuthorized: Bool { get }

    /// 権限状態の説明テキスト
    var authorizationStatusDescription: String { get }

    /// 権限要求
    func requestAuthorization() async

    /// 歩数取得
    func fetchStepCount(for date: Date) async -> Double

    /// 距離取得（km）
    func fetchDistance(for date: Date) async -> Double

    /// 消費カロリー取得
    func fetchCalories(for date: Date) async -> Double

    /// 運動時間取得（分）
    func fetchExerciseTime(for date: Date) async -> Double

    /// 睡眠データ取得
    func fetchSleepData(for date: Date) async -> (duration: Double, efficiency: Double)?

    /// カテゴリ別のデータ取得
    func fetchData(for category: HealthCategory, date: Date) async -> Double

    /// 期間指定でのメトリクス取得
    func fetchMetrics(for category: HealthCategory, in period: TimePeriod, from date: Date, goals: [HealthGoal]) async -> [HealthMetric]
}
