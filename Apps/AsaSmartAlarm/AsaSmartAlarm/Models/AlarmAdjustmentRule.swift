//
//  AlarmAdjustmentRule.swift
//  AsaSmartAlarm
//
//  アラーム調整ルールモデル
//

import Foundation
import SwiftData

// MARK: - アラーム調整ルール

/// 天気やイベントに応じたアラーム調整ルール
@Model
final class AlarmAdjustmentRule {
    // MARK: - Properties

    var id: UUID
    var conditionTypeRawValue: String
    var weatherConditionRawValue: String?
    var adjustmentMinutes: Int  // 正=早める、負=遅らせる
    var isEnabled: Bool
    var createdAt: Date

    // MARK: - Relationship

    var alarm: SmartAlarm?

    // MARK: - Computed Properties

    /// 条件タイプ（天気 or イベント）
    var conditionType: ConditionType {
        get { ConditionType(rawValue: conditionTypeRawValue) ?? .weather }
        set { conditionTypeRawValue = newValue.rawValue }
    }

    /// 天気条件（天気タイプの場合のみ使用）
    var weatherCondition: WeatherCondition? {
        get {
            guard let raw = weatherConditionRawValue else { return nil }
            return WeatherCondition(rawValue: raw)
        }
        set { weatherConditionRawValue = newValue?.rawValue }
    }

    /// 調整時間の表示文字列
    var adjustmentDescription: String {
        if adjustmentMinutes == 0 {
            return "調整なし"
        } else if adjustmentMinutes > 0 {
            return "\(adjustmentMinutes)分早く"
        } else {
            return "\(abs(adjustmentMinutes))分遅く"
        }
    }

    /// ルールの説明
    var ruleDescription: String {
        switch conditionType {
        case .weather:
            let conditionName = weatherCondition?.displayName ?? "不明"
            return "\(conditionName)の場合、\(adjustmentDescription)"
        case .event:
            return "予定がある場合、\(adjustmentDescription)"
        }
    }

    // MARK: - Initializer

    init(
        conditionType: ConditionType,
        weatherCondition: WeatherCondition? = nil,
        adjustmentMinutes: Int,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.conditionTypeRawValue = conditionType.rawValue
        self.weatherConditionRawValue = weatherCondition?.rawValue
        self.adjustmentMinutes = adjustmentMinutes
        self.isEnabled = isEnabled
        self.createdAt = Date()
    }

    // MARK: - Factory Methods

    /// 天気条件用のルールを作成
    static func weatherRule(
        condition: WeatherCondition,
        adjustmentMinutes: Int? = nil,
        isEnabled: Bool = true
    ) -> AlarmAdjustmentRule {
        AlarmAdjustmentRule(
            conditionType: .weather,
            weatherCondition: condition,
            adjustmentMinutes: adjustmentMinutes ?? condition.defaultAdjustmentMinutes,
            isEnabled: isEnabled
        )
    }

    /// イベント条件用のルールを作成
    static func eventRule(
        adjustmentMinutes: Int = 0,
        isEnabled: Bool = true
    ) -> AlarmAdjustmentRule {
        AlarmAdjustmentRule(
            conditionType: .event,
            weatherCondition: nil,
            adjustmentMinutes: adjustmentMinutes,
            isEnabled: isEnabled
        )
    }

    /// デフォルトの天気ルールセットを作成
    static func defaultWeatherRules() -> [AlarmAdjustmentRule] {
        [
            weatherRule(condition: .rain, isEnabled: true),
            weatherRule(condition: .snow, isEnabled: true),
            weatherRule(condition: .thunderstorm, isEnabled: true),
            weatherRule(condition: .fog, isEnabled: false),
            weatherRule(condition: .clear, isEnabled: false),
            weatherRule(condition: .clouds, isEnabled: false)
        ]
    }
}
