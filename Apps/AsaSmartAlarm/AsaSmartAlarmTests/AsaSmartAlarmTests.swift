//
//  AsaSmartAlarmTests.swift
//  AsaSmartAlarmTests
//
//  AsaSmartAlarmのテストスイート
//

import Testing
import Foundation
@testable import AsaSmartAlarm

// MARK: - 天気条件テスト

@Suite("WeatherCondition Tests")
struct WeatherConditionTests {

    @Test("天気コードマッピング - 晴れ")
    func testWeatherCodeMappingClear() {
        #expect(WeatherCondition.from(weatherCode: 0) == .clear)
        #expect(WeatherCondition.from(weatherCode: 1) == .clear)
    }

    @Test("天気コードマッピング - 曇り")
    func testWeatherCodeMappingClouds() {
        #expect(WeatherCondition.from(weatherCode: 2) == .clouds)
        #expect(WeatherCondition.from(weatherCode: 3) == .clouds)
    }

    @Test("天気コードマッピング - 雨")
    func testWeatherCodeMappingRain() {
        #expect(WeatherCondition.from(weatherCode: 61) == .rain)
        #expect(WeatherCondition.from(weatherCode: 63) == .rain)
        #expect(WeatherCondition.from(weatherCode: 80) == .rain)
    }

    @Test("天気コードマッピング - 雪")
    func testWeatherCodeMappingSnow() {
        #expect(WeatherCondition.from(weatherCode: 71) == .snow)
        #expect(WeatherCondition.from(weatherCode: 85) == .snow)
    }

    @Test("天気コードマッピング - 雷雨")
    func testWeatherCodeMappingThunderstorm() {
        #expect(WeatherCondition.from(weatherCode: 95) == .thunderstorm)
        #expect(WeatherCondition.from(weatherCode: 96) == .thunderstorm)
    }

    @Test("デフォルト調整時間")
    func testDefaultAdjustmentMinutes() {
        #expect(WeatherCondition.clear.defaultAdjustmentMinutes == 0)
        #expect(WeatherCondition.rain.defaultAdjustmentMinutes == 15)
        #expect(WeatherCondition.snow.defaultAdjustmentMinutes == 30)
        #expect(WeatherCondition.thunderstorm.defaultAdjustmentMinutes == 20)
    }
}

// MARK: - スマートアラームテスト

@Suite("SmartAlarm Tests")
struct SmartAlarmTests {

    @Test("アラーム作成")
    func testAlarmCreation() {
        let calendar = Calendar.current
        let baseTime = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!

        let alarm = SmartAlarm(
            baseTime: baseTime,
            label: "テストアラーム",
            isEnabled: true,
            repeatDays: [1, 2, 3, 4, 5]
        )

        #expect(alarm.label == "テストアラーム")
        #expect(alarm.isEnabled == true)
        #expect(alarm.repeatDays == [1, 2, 3, 4, 5])
        #expect(alarm.timeString == "06:30")
    }

    @Test("繰り返し曜日の表示 - 平日")
    func testRepeatDaysDescriptionWeekdays() {
        let alarm = SmartAlarm(
            baseTime: Date(),
            repeatDays: [1, 2, 3, 4, 5]
        )
        #expect(alarm.repeatDaysDescription == "平日")
    }

    @Test("繰り返し曜日の表示 - 週末")
    func testRepeatDaysDescriptionWeekend() {
        let alarm = SmartAlarm(
            baseTime: Date(),
            repeatDays: [0, 6]
        )
        #expect(alarm.repeatDaysDescription == "週末")
    }

    @Test("繰り返し曜日の表示 - 毎日")
    func testRepeatDaysDescriptionEveryDay() {
        let alarm = SmartAlarm(
            baseTime: Date(),
            repeatDays: [0, 1, 2, 3, 4, 5, 6]
        )
        #expect(alarm.repeatDaysDescription == "毎日")
    }

    @Test("繰り返し曜日の表示 - 1回のみ")
    func testRepeatDaysDescriptionOnce() {
        let alarm = SmartAlarm(
            baseTime: Date(),
            repeatDays: []
        )
        #expect(alarm.repeatDaysDescription == "1回のみ")
    }

    @Test("次回アラーム日時の計算 - 繰り返しなし")
    func testCalculateNextDateNoRepeat() {
        let calendar = Calendar.current

        // 明日の6:30
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 30
        let baseTime = calendar.date(from: components)!

        let alarm = SmartAlarm(baseTime: baseTime, repeatDays: [])

        let nextDate = alarm.calculateNextDate(from: Date())
        #expect(nextDate != nil)
    }

    @Test("デフォルト天気ルールのセットアップ")
    func testSetupDefaultWeatherRules() {
        let alarm = SmartAlarm(baseTime: Date())
        alarm.setupDefaultWeatherRules()

        #expect(alarm.adjustmentRules.count == 6)

        // 雨のルールを確認
        let rainRule = alarm.rule(for: .rain)
        #expect(rainRule != nil)
        #expect(rainRule?.adjustmentMinutes == 15)
        #expect(rainRule?.isEnabled == true)
    }
}

// MARK: - 調整ルールテスト

@Suite("AlarmAdjustmentRule Tests")
struct AlarmAdjustmentRuleTests {

    @Test("天気ルールの作成")
    func testWeatherRuleCreation() {
        let rule = AlarmAdjustmentRule.weatherRule(
            condition: .rain,
            adjustmentMinutes: 20,
            isEnabled: true
        )

        #expect(rule.conditionType == .weather)
        #expect(rule.weatherCondition == .rain)
        #expect(rule.adjustmentMinutes == 20)
        #expect(rule.isEnabled == true)
    }

    @Test("イベントルールの作成")
    func testEventRuleCreation() {
        let rule = AlarmAdjustmentRule.eventRule(
            adjustmentMinutes: 30,
            isEnabled: true
        )

        #expect(rule.conditionType == .event)
        #expect(rule.weatherCondition == nil)
        #expect(rule.adjustmentMinutes == 30)
    }

    @Test("調整説明文 - 早める")
    func testAdjustmentDescriptionEarlier() {
        let rule = AlarmAdjustmentRule.weatherRule(condition: .rain, adjustmentMinutes: 15)
        #expect(rule.adjustmentDescription == "15分早く")
    }

    @Test("調整説明文 - 調整なし")
    func testAdjustmentDescriptionNone() {
        let rule = AlarmAdjustmentRule.weatherRule(condition: .clear, adjustmentMinutes: 0)
        #expect(rule.adjustmentDescription == "調整なし")
    }
}

// MARK: - カレンダーイベントテスト

@Suite("CalendarEvent Tests")
struct CalendarEventTests {

    @Test("イベント作成")
    func testEventCreation() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 9
        components.minute = 0
        let startTime = calendar.date(from: components)!

        let event = CalendarEvent(
            title: "朝会議",
            startTime: startTime,
            preparationMinutes: 30,
            travelMinutes: 45
        )

        #expect(event.title == "朝会議")
        #expect(event.preparationMinutes == 30)
        #expect(event.travelMinutes == 45)
        #expect(event.totalPreparationMinutes == 75)
    }

    @Test("推奨起床時刻の計算")
    func testSuggestedWakeUpTime() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 9
        components.minute = 0
        let startTime = calendar.date(from: components)!

        let event = CalendarEvent(
            title: "テスト",
            startTime: startTime,
            preparationMinutes: 30,
            travelMinutes: 30
        )

        // 9:00 - 60分 = 8:00
        let suggestedTime = event.suggestedWakeUpTime
        let suggestedHour = calendar.component(.hour, from: suggestedTime)
        let suggestedMinute = calendar.component(.minute, from: suggestedTime)

        #expect(suggestedHour == 8)
        #expect(suggestedMinute == 0)
    }

    @Test("朝イベント判定")
    func testIsMorningEvent() {
        let calendar = Calendar.current

        // 9:00のイベント
        var morningComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        morningComponents.day! += 1
        morningComponents.hour = 9
        morningComponents.minute = 0
        let morningEvent = CalendarEvent(
            title: "朝",
            startTime: calendar.date(from: morningComponents)!
        )
        #expect(morningEvent.isMorningEvent == true)

        // 14:00のイベント
        var afternoonComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        afternoonComponents.day! += 1
        afternoonComponents.hour = 14
        afternoonComponents.minute = 0
        let afternoonEvent = CalendarEvent(
            title: "午後",
            startTime: calendar.date(from: afternoonComponents)!
        )
        #expect(afternoonEvent.isMorningEvent == false)
    }
}

// MARK: - アラーム計算結果テスト

@Suite("AlarmCalculationResult Tests")
struct AlarmCalculationResultTests {

    @Test("調整サマリー - 調整あり")
    func testAdjustmentSummaryWithAdjustments() {
        let result = AlarmCalculationResult.previewWithAdjustments
        #expect(result.hasAdjustments == true)
        #expect(result.totalAdjustmentMinutes == 15)
    }

    @Test("調整サマリー - 調整なし")
    func testAdjustmentSummaryNoAdjustments() {
        let result = AlarmCalculationResult.previewNoAdjustments
        #expect(result.hasAdjustments == false)
        #expect(result.adjustmentSummary == "調整なし")
    }

    @Test("時刻変更説明 - 早める")
    func testTimeChangeDescriptionEarlier() {
        let calendar = Calendar.current
        let originalTime = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!

        let result = AlarmCalculationResult(
            originalTime: originalTime,
            adjustedTime: originalTime.addingTimeInterval(-15 * 60),
            totalAdjustmentMinutes: 15,
            adjustments: []
        )

        #expect(result.timeChangeDescription == "15分早く")
    }

    @Test("時刻変更説明 - 変更なし")
    func testTimeChangeDescriptionNoChange() {
        let time = Date()
        let result = AlarmCalculationResult(
            originalTime: time,
            adjustedTime: time,
            totalAdjustmentMinutes: 0,
            adjustments: []
        )

        #expect(result.timeChangeDescription == "変更なし")
    }
}

// MARK: - 設定テスト

@Suite("AlarmSettings Tests")
struct AlarmSettingsTests {

    @Test("デフォルト設定")
    func testDefaultSettings() {
        let settings = AlarmSettings()

        #expect(settings.notificationsEnabled == true)
        #expect(settings.snoozeMinutes == 5)
        #expect(settings.maxSnoozeCount == 3)
        #expect(settings.weatherUpdateEnabled == true)
        #expect(settings.weatherCheckHour == 20)
    }

    @Test("位置情報の保存")
    func testSaveLocation() {
        let settings = AlarmSettings()
        settings.saveLocation(latitude: 35.6762, longitude: 139.6503, name: "東京")

        #expect(settings.hasSavedLocation == true)
        #expect(settings.savedLatitude == 35.6762)
        #expect(settings.savedLongitude == 139.6503)
        #expect(settings.savedLocationName == "東京")
    }

    @Test("設定リセット")
    func testResetToDefaults() {
        let settings = AlarmSettings()
        settings.snoozeMinutes = 10
        settings.saveLocation(latitude: 35.0, longitude: 139.0, name: "テスト")

        settings.resetToDefaults()

        #expect(settings.snoozeMinutes == 5)
        #expect(settings.hasSavedLocation == false)
    }
}
