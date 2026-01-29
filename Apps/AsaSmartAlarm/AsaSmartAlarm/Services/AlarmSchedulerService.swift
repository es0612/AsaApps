//
//  AlarmSchedulerService.swift
//  AsaSmartAlarm
//
//  アラームのスマートスケジューリングサービス
//

import Foundation

// MARK: - アラーム計算結果

/// スマートアラーム計算の結果
struct AlarmCalculationResult {
    let originalTime: Date          // 基準時刻
    let adjustedTime: Date          // 調整後の時刻
    let totalAdjustmentMinutes: Int // 総調整時間（分）
    let adjustments: [AdjustmentDetail]  // 適用された調整の詳細

    /// 調整があるかどうか
    var hasAdjustments: Bool {
        !adjustments.isEmpty
    }

    /// 調整の要約
    var adjustmentSummary: String {
        if adjustments.isEmpty {
            return "調整なし"
        }

        let descriptions = adjustments.map { $0.description }
        return descriptions.joined(separator: "、")
    }

    /// 時刻変更の説明
    var timeChangeDescription: String {
        if totalAdjustmentMinutes == 0 {
            return "変更なし"
        } else if totalAdjustmentMinutes > 0 {
            return "\(totalAdjustmentMinutes)分早く"
        } else {
            return "\(abs(totalAdjustmentMinutes))分遅く"
        }
    }
}

/// 調整の詳細
struct AdjustmentDetail: Identifiable {
    let id = UUID()
    let type: AdjustmentType
    let reason: String
    let minutes: Int  // 正=早める、負=遅らせる

    var description: String {
        let direction = minutes > 0 ? "早める" : "遅らせる"
        return "\(reason)（\(abs(minutes))分\(direction)）"
    }
}

/// 調整タイプ
enum AdjustmentType {
    case weather
    case event
}

// MARK: - アラームスケジューラーサービス

/// アラームのスマートスケジューリングを行うサービス
@MainActor
final class AlarmSchedulerService {
    // MARK: - Properties

    private let weatherService = WeatherService.shared
    private let notificationService = NotificationService.shared

    // MARK: - Public Methods

    /// 次回のアラーム時刻を計算（天気とイベントを考慮）
    /// - Parameters:
    ///   - alarm: アラームモデル
    ///   - weatherForecast: 天気予報（オプション）
    ///   - events: イベントリスト（オプション）
    /// - Returns: 計算結果
    func calculateNextAlarmTime(
        for alarm: SmartAlarm,
        weatherForecast: MorningWeatherForecast? = nil,
        events: [CalendarEvent] = []
    ) -> AlarmCalculationResult? {
        // 基準となる次回アラーム時刻を取得
        guard let baseNextDate = alarm.calculateNextDate(from: Date()) else {
            return nil
        }

        var adjustments: [AdjustmentDetail] = []
        var totalMinutes = 0

        // 天気による調整
        if alarm.weatherAdjustmentEnabled, let forecast = weatherForecast {
            if let weatherAdjustment = calculateWeatherAdjustment(
                alarm: alarm,
                forecast: forecast
            ) {
                adjustments.append(weatherAdjustment)
                totalMinutes += weatherAdjustment.minutes
            }
        }

        // イベントによる調整
        if alarm.eventAdjustmentEnabled {
            if let eventAdjustment = calculateEventAdjustment(
                baseTime: baseNextDate,
                events: events
            ) {
                adjustments.append(eventAdjustment)
                totalMinutes += eventAdjustment.minutes
            }
        }

        // 調整後の時刻を計算（分単位で早める＝マイナス秒数）
        let adjustedTime = baseNextDate.addingTimeInterval(
            TimeInterval(-totalMinutes * 60)
        )

        return AlarmCalculationResult(
            originalTime: baseNextDate,
            adjustedTime: adjustedTime,
            totalAdjustmentMinutes: totalMinutes,
            adjustments: adjustments
        )
    }

    /// アラームの通知をスケジュール
    /// - Parameters:
    ///   - alarm: アラームモデル
    ///   - calculationResult: 計算結果
    func scheduleAlarm(
        _ alarm: SmartAlarm,
        with calculationResult: AlarmCalculationResult
    ) async {
        let adjustmentInfo = calculationResult.hasAdjustments
            ? calculationResult.adjustmentSummary
            : nil

        await notificationService.scheduleAlarmNotification(
            for: alarm,
            at: calculationResult.adjustedTime,
            adjustmentInfo: adjustmentInfo
        )
    }

    /// アラームの通知をキャンセル
    func cancelAlarm(_ alarm: SmartAlarm) async {
        await notificationService.cancelNotification(for: alarm.id)
    }

    /// 複数のアラームを一括スケジュール
    func scheduleAllAlarms(
        _ alarms: [SmartAlarm],
        weatherForecast: MorningWeatherForecast?,
        events: [CalendarEvent]
    ) async {
        for alarm in alarms where alarm.isEnabled {
            if let result = calculateNextAlarmTime(
                for: alarm,
                weatherForecast: weatherForecast,
                events: events
            ) {
                await scheduleAlarm(alarm, with: result)
            }
        }
    }

    // MARK: - Private Methods

    /// 天気による調整を計算
    private func calculateWeatherAdjustment(
        alarm: SmartAlarm,
        forecast: MorningWeatherForecast
    ) -> AdjustmentDetail? {
        // アラームの天気ルールを確認
        let enabledRules = alarm.enabledWeatherRules

        // 予報の天気条件に対応するルールを探す
        for rule in enabledRules {
            if let condition = rule.weatherCondition,
               condition == forecast.dominantCondition,
               rule.adjustmentMinutes != 0 {
                return AdjustmentDetail(
                    type: .weather,
                    reason: "\(condition.displayName)予報",
                    minutes: rule.adjustmentMinutes
                )
            }
        }

        return nil
    }

    /// イベントによる調整を計算
    private func calculateEventAdjustment(
        baseTime: Date,
        events: [CalendarEvent]
    ) -> AdjustmentDetail? {
        let calendar = Calendar.current

        // 同じ日の朝のイベントを探す
        let morningEvents = events.filter { event in
            // 同じ日かつ朝のイベント
            calendar.isDate(event.startTime, inSameDayAs: baseTime) &&
            event.isMorningEvent &&
            !event.isAllDay
        }

        // 最も早い朝イベントを取得
        guard let earliestEvent = morningEvents.min(by: { $0.startTime < $1.startTime }) else {
            return nil
        }

        // イベントの推奨起床時刻を計算
        let suggestedWakeUp = earliestEvent.suggestedWakeUpTime

        // 基準時刻より早い起床が必要な場合のみ調整
        if suggestedWakeUp < baseTime {
            let differenceMinutes = Int(
                baseTime.timeIntervalSince(suggestedWakeUp) / 60
            )

            if differenceMinutes > 0 {
                return AdjustmentDetail(
                    type: .event,
                    reason: "「\(earliestEvent.title)」の準備",
                    minutes: differenceMinutes
                )
            }
        }

        return nil
    }
}

// MARK: - Preview Support

extension AlarmCalculationResult {
    /// プレビュー用の計算結果（調整あり）
    static var previewWithAdjustments: AlarmCalculationResult {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 6
        components.minute = 30
        let originalTime = calendar.date(from: components)!

        return AlarmCalculationResult(
            originalTime: originalTime,
            adjustedTime: originalTime.addingTimeInterval(-15 * 60),
            totalAdjustmentMinutes: 15,
            adjustments: [
                AdjustmentDetail(
                    type: .weather,
                    reason: "雨予報",
                    minutes: 15
                )
            ]
        )
    }

    /// プレビュー用の計算結果（調整なし）
    static var previewNoAdjustments: AlarmCalculationResult {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 6
        components.minute = 30
        let time = calendar.date(from: components)!

        return AlarmCalculationResult(
            originalTime: time,
            adjustedTime: time,
            totalAdjustmentMinutes: 0,
            adjustments: []
        )
    }
}
