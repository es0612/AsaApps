import Testing
import Foundation
@testable import AsaLifeLogKit

// MARK: - LifeLogEntry Tests

@Suite("LifeLogEntry Model")
struct LifeLogEntryTests {
    @Test("デフォルト初期化が正しい")
    func defaultInit() {
        let entry = LifeLogEntry()
        #expect(entry.title == "")
        #expect(entry.content == nil)
        #expect(entry.entryType == .manual)
        #expect(entry.moodScore == nil)
        #expect(entry.tags.isEmpty)
        #expect(entry.source == .manual)
        #expect(entry.isFavorite == false)
        #expect(entry.latitude == nil)
        #expect(entry.longitude == nil)
    }

    @Test("カスタム初期化が正しい")
    func customInit() {
        let entry = LifeLogEntry(
            entryType: .mood,
            title: "気分記録",
            content: "今日は良い日",
            moodScore: .great,
            tags: ["朝活", "運動"],
            source: .manual
        )
        #expect(entry.title == "気分記録")
        #expect(entry.content == "今日は良い日")
        #expect(entry.entryType == .mood)
        #expect(entry.moodScore == .great)
        #expect(entry.tags == ["朝活", "運動"])
        #expect(entry.source == .manual)
    }

    @Test("entryType の computed property が正しく動作する")
    func entryTypeComputed() {
        let entry = LifeLogEntry()
        entry.entryType = .health
        #expect(entry.entryTypeRawValue == "health")
        #expect(entry.entryType == .health)
    }

    @Test("moodScore の computed property が正しく動作する")
    func moodScoreComputed() {
        let entry = LifeLogEntry()
        #expect(entry.moodScore == nil)

        entry.moodScore = .good
        #expect(entry.moodScoreRawValue == "good")
        #expect(entry.moodScore == .good)

        entry.moodScore = nil
        #expect(entry.moodScoreRawValue == nil)
    }

    @Test("activityType の computed property が正しく動作する")
    func activityTypeComputed() {
        let entry = LifeLogEntry()
        #expect(entry.activityType == nil)

        entry.activityType = .running
        #expect(entry.activityTypeRawValue == "running")
        #expect(entry.activityType == .running)
    }

    @Test("source の computed property が正しく動作する")
    func sourceComputed() {
        let entry = LifeLogEntry(source: .healthKit)
        #expect(entry.sourceRawValue == "healthKit")
        #expect(entry.source == .healthKit)
    }

    @Test("位置情報を設定できる")
    func locationProperties() {
        let entry = LifeLogEntry(
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: "東京駅"
        )
        #expect(entry.latitude == 35.6762)
        #expect(entry.longitude == 139.6503)
        #expect(entry.locationName == "東京駅")
    }

    @Test("ヘルスメトリックを設定できる")
    func healthMetricProperties() {
        let entry = LifeLogEntry(
            entryType: .health,
            title: "歩数",
            source: .healthKit,
            healthMetricTypeRawValue: "steps",
            healthMetricValue: 8500.0
        )
        #expect(entry.healthMetricTypeRawValue == "steps")
        #expect(entry.healthMetricValue == 8500.0)
    }

    @Test("不正な rawValue は nil またはデフォルト値を返す")
    func invalidRawValues() {
        let entry = LifeLogEntry()
        entry.entryTypeRawValue = "invalid"
        #expect(entry.entryType == .manual) // デフォルトにフォールバック

        entry.moodScoreRawValue = "invalid"
        #expect(entry.moodScore == nil)

        entry.sourceRawValue = "invalid"
        #expect(entry.source == .manual) // デフォルトにフォールバック
    }
}

// MARK: - DailySummary Tests

@Suite("DailySummary Model")
struct DailySummaryTests {
    @Test("デフォルト初期化が正しい")
    func defaultInit() {
        let summary = DailySummary()
        #expect(summary.entryCount == 0)
        #expect(summary.totalSteps == 0)
        #expect(summary.moodAverage == nil)
        #expect(summary.sleepHours == nil)
        #expect(summary.visitedPlaces.isEmpty)
    }

    @Test("カスタム初期化が正しい")
    func customInit() {
        let summary = DailySummary(
            entryCount: 10,
            moodAverage: 4.2,
            totalSteps: 8000,
            sleepHours: 7.5,
            dominantActivity: .walking,
            visitedPlaces: ["渋谷", "新宿"],
            photoCount: 3
        )
        #expect(summary.entryCount == 10)
        #expect(summary.totalSteps == 8000)
        #expect(summary.visitedPlaces.count == 2)
        #expect(summary.photoCount == 3)
    }

    @Test("morningScore が正しく計算される")
    func morningScore() {
        let summary = DailySummary(entryCount: 3, moodAverage: 4.0)
        // entryScore = min(3 * 10, 50) = 30
        // moodScore = Int(4.0 * 10.0) = 40
        // total = min(30 + 40, 100) = 70
        #expect(summary.morningScore == 70)
    }

    @Test("morningScore が moodAverage nil のとき中間値を使う")
    func morningScoreWithNilMood() {
        let summary = DailySummary(entryCount: 2)
        // entryScore = min(2 * 10, 50) = 20
        // moodScore = Int(3.0 * 10.0) = 30 (デフォルト)
        // total = min(20 + 30, 100) = 50
        #expect(summary.morningScore == 50)
    }

    @Test("morningScore の上限が100")
    func morningScoreMax() {
        let summary = DailySummary(entryCount: 10, moodAverage: 5.0)
        // entryScore = min(10 * 10, 50) = 50
        // moodScore = Int(5.0 * 10.0) = 50
        // total = min(50 + 50, 100) = 100
        #expect(summary.morningScore == 100)
    }

    @Test("dominantActivity の computed property が正しく動作する")
    func dominantActivityComputed() {
        let summary = DailySummary(dominantActivity: .cycling)
        #expect(summary.dominantActivity == .cycling)
        #expect(summary.dominantActivityRawValue == "cycling")
    }
}

// MARK: - WeeklySummary Tests

@Suite("WeeklySummary Model")
struct WeeklySummaryTests {
    @Test("デフォルト初期化が正しい")
    func defaultInit() {
        let summary = WeeklySummary()
        #expect(summary.entryCount == 0)
        #expect(summary.averageMood == nil)
        #expect(summary.totalSteps == 0)
        #expect(summary.topTags.isEmpty)
    }

    @Test("カスタム初期化が正しい")
    func customInit() {
        let summary = WeeklySummary(
            entryCount: 42,
            averageMood: 3.8,
            totalSteps: 50000,
            averageSleepHours: 7.2,
            topTags: ["朝活", "運動", "読書"]
        )
        #expect(summary.entryCount == 42)
        #expect(summary.totalSteps == 50000)
        #expect(summary.topTags.count == 3)
    }
}

// MARK: - PlaceLog Tests

@Suite("PlaceLog Model")
struct PlaceLogTests {
    @Test("デフォルト初期化が正しい")
    func defaultInit() {
        let place = PlaceLog()
        #expect(place.name == "")
        #expect(place.category == .other)
        #expect(place.visitCount == 0)
        #expect(place.isFavorite == false)
    }

    @Test("カスタム初期化が正しい")
    func customInit() {
        let place = PlaceLog(
            name: "スターバックス渋谷",
            latitude: 35.6614,
            longitude: 139.7010,
            category: .restaurant,
            visitCount: 15,
            isFavorite: true
        )
        #expect(place.name == "スターバックス渋谷")
        #expect(place.category == .restaurant)
        #expect(place.visitCount == 15)
        #expect(place.isFavorite == true)
    }

    @Test("category の computed property が正しく動作する")
    func categoryComputed() {
        let place = PlaceLog()
        place.category = .gym
        #expect(place.categoryRawValue == "gym")
        #expect(place.category == .gym)
    }
}

// MARK: - UserPreferences Tests

@Suite("UserPreferences Model")
struct UserPreferencesTests {
    @Test("デフォルト初期化が正しい")
    func defaultInit() {
        let prefs = UserPreferences()
        #expect(prefs.enableHealthTracking == true)
        #expect(prefs.enableLocationTracking == true)
        #expect(prefs.enablePhotoIntegration == true)
        #expect(prefs.enableActivityRecognition == true)
        #expect(prefs.enableAIInsights == true)
        #expect(prefs.morningRoutineStartHour == 5)
        #expect(prefs.morningRoutineEndHour == 7)
        #expect(prefs.preferredChartPeriod == .week)
    }

    @Test("カスタム初期化が正しい")
    func customInit() {
        let prefs = UserPreferences(
            enableHealthTracking: false,
            preferredChartPeriod: .month,
            morningRoutineStartHour: 4,
            morningRoutineEndHour: 8
        )
        #expect(prefs.enableHealthTracking == false)
        #expect(prefs.preferredChartPeriod == .month)
        #expect(prefs.morningRoutineStartHour == 4)
        #expect(prefs.morningRoutineEndHour == 8)
    }

    @Test("preferredChartPeriod の computed property が正しく動作する")
    func chartPeriodComputed() {
        let prefs = UserPreferences()
        prefs.preferredChartPeriod = .year
        #expect(prefs.preferredChartPeriodRawValue == "year")
        #expect(prefs.preferredChartPeriod == .year)
    }
}

// MARK: - Supporting Types Tests

@Suite("SupportingTypes")
struct SupportingTypesTests {
    @Test("PhotoAssetInfo が正しく初期化される")
    func photoAssetInfoInit() {
        let now = Date()
        let photo = PhotoAssetInfo(
            id: "asset123",
            createdDate: now,
            location: PhotoLocation(latitude: 35.0, longitude: 139.0)
        )
        #expect(photo.id == "asset123")
        #expect(photo.createdDate == now)
        #expect(photo.location?.latitude == 35.0)
        #expect(photo.location?.longitude == 139.0)
    }

    @Test("PhotoAssetInfo は location なしでも生成できる")
    func photoAssetInfoWithoutLocation() {
        let photo = PhotoAssetInfo(id: "asset456")
        #expect(photo.id == "asset456")
        #expect(photo.createdDate == nil)
        #expect(photo.location == nil)
    }

    @Test("PhotoLocation が正しく初期化される")
    func photoLocationInit() {
        let loc = PhotoLocation(latitude: 35.6762, longitude: 139.6503)
        #expect(loc.latitude == 35.6762)
        #expect(loc.longitude == 139.6503)
    }

    @Test("ActivityRecord が正しく初期化される")
    func activityRecordInit() {
        let start = Date()
        let end = Date().addingTimeInterval(3600)
        let record = ActivityRecord(
            startDate: start,
            endDate: end,
            activityType: .running,
            confidence: 0.95
        )
        #expect(record.activityType == .running)
        #expect(record.confidence == 0.95)
        #expect(record.startDate == start)
        #expect(record.endDate == end)
    }

    @Test("DailyInsightResult が正しく初期化される")
    func dailyInsightResultInit() {
        let result = DailyInsightResult(
            date: Date(),
            summaryText: "充実した一日",
            morningScore: 85,
            highlightEntryId: nil,
            suggestions: ["運動しましょう", "水を飲みましょう"]
        )
        #expect(result.summaryText == "充実した一日")
        #expect(result.morningScore == 85)
        #expect(result.suggestions.count == 2)
    }

    @Test("WeeklyInsightResult が正しく初期化される")
    func weeklyInsightResultInit() {
        let result = WeeklyInsightResult(
            weekStartDate: Date(),
            summaryText: "良い週でした",
            topTags: ["朝活", "読書"],
            moodTrend: "上昇傾向"
        )
        #expect(result.summaryText == "良い週でした")
        #expect(result.topTags.count == 2)
        #expect(result.moodTrend == "上昇傾向")
    }

    @Test("PatternResult が正しく初期化される")
    func patternResultInit() {
        let pattern = PatternResult(
            patternType: "mood_activity",
            description: "運動すると気分が良い",
            confidence: 0.8,
            relatedTags: ["運動", "気分"]
        )
        #expect(pattern.patternType == "mood_activity")
        #expect(pattern.description == "運動すると気分が良い")
        #expect(pattern.confidence == 0.8)
        #expect(pattern.relatedTags.count == 2)
    }
}
