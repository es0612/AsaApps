import Testing
import Foundation
@testable import AsaLifeLogKit

// MARK: - InsightsEngine Tests

@Suite("InsightsEngine", .tags(.service))
@MainActor
struct InsightsEngineTests {
    let engine = InsightsEngine()

    @Test("朝活時間帯エントリーがない場合スコアは0")
    func morningScoreEmpty() {
        let prefs = UserPreferences(morningRoutineStartHour: 5, morningRoutineEndHour: 7)
        let score = engine.calculateMorningScore(entries: [], preferences: prefs)
        #expect(score == 0)
    }

    @Test("朝活スコアが正しく計算される")
    func morningScoreCalculation() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 0
        let morningDate = calendar.date(from: components)!

        let entry1 = LifeLogEntry(timestamp: morningDate, entryType: .manual, title: "朝活1", moodScore: .great)
        let entry2 = LifeLogEntry(timestamp: morningDate.addingTimeInterval(600), entryType: .mood, title: "朝活2", moodScore: .good)

        let prefs = UserPreferences(morningRoutineStartHour: 5, morningRoutineEndHour: 7)
        let score = engine.calculateMorningScore(entries: [entry1, entry2], preferences: prefs)

        // densityScore = min(2 * 15, 50) = 30
        // moodScore: avg = (5+4)/2 = 4.5, Int(4.5 * 6.0) = 27
        // diversityScore = min(2 * 5, 20) = 10
        // total = min(30 + 27 + 10, 100) = 67
        #expect(score == 67)
    }

    @Test("朝活スコアの上限が100")
    func morningScoreMax() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        let morningDate = calendar.date(from: components)!

        // 4種類のエントリーを作る（多様性スコアを上げる）
        let entries = [
            LifeLogEntry(timestamp: morningDate, entryType: .manual, title: "1", moodScore: .great),
            LifeLogEntry(timestamp: morningDate.addingTimeInterval(60), entryType: .mood, title: "2", moodScore: .great),
            LifeLogEntry(timestamp: morningDate.addingTimeInterval(120), entryType: .health, title: "3", moodScore: .great),
            LifeLogEntry(timestamp: morningDate.addingTimeInterval(180), entryType: .activity, title: "4", moodScore: .great),
        ]

        let prefs = UserPreferences(morningRoutineStartHour: 5, morningRoutineEndHour: 7)
        let score = engine.calculateMorningScore(entries: entries, preferences: prefs)
        #expect(score <= 100)
    }

    @Test("気分なしのエントリーは朝活スコアでデフォルト中間値を使う")
    func morningScoreWithoutMood() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        let morningDate = calendar.date(from: components)!

        let entry = LifeLogEntry(timestamp: morningDate, entryType: .manual, title: "test")
        let prefs = UserPreferences(morningRoutineStartHour: 5, morningRoutineEndHour: 7)
        let score = engine.calculateMorningScore(entries: [entry], preferences: prefs)

        // densityScore = min(1 * 15, 50) = 15
        // moodScore = 15 (デフォルト)
        // diversityScore = min(1 * 5, 20) = 5
        // total = 35
        #expect(score == 35)
    }

    @Test("日次インサイトが生成される")
    func generateDailyInsight() {
        let entry = LifeLogEntry(entryType: .manual, title: "テスト", moodScore: .good)
        let prefs = UserPreferences()
        let result = engine.generateDailyInsight(entries: [entry], date: Date(), preferences: prefs)

        #expect(!result.summaryText.isEmpty)
        #expect(result.summaryText.contains("1件"))
    }

    @Test("日次インサイトのサマリーに気分情報が含まれる")
    func dailyInsightWithMood() {
        let entries = [
            LifeLogEntry(entryType: .mood, title: "good", moodScore: .great),
            LifeLogEntry(entryType: .mood, title: "also good", moodScore: .good),
        ]
        let prefs = UserPreferences()
        let result = engine.generateDailyInsight(entries: entries, date: Date(), preferences: prefs)
        #expect(result.summaryText.contains("気分"))
    }

    @Test("ハイライトエントリーはお気に入りを優先する")
    func highlightPreferseFavorite() {
        let favorite = LifeLogEntry(entryType: .manual, title: "お気に入り")
        favorite.isFavorite = true
        let normal = LifeLogEntry(entryType: .mood, title: "通常", moodScore: .great)

        let prefs = UserPreferences()
        let result = engine.generateDailyInsight(entries: [normal, favorite], date: Date(), preferences: prefs)
        #expect(result.highlightEntryId == favorite.id)
    }

    @Test("提案が気分未記録のとき生成される")
    func suggestionsForNoMood() {
        let entry = LifeLogEntry(entryType: .manual, title: "テスト")
        let prefs = UserPreferences()
        let result = engine.generateDailyInsight(entries: [entry], date: Date(), preferences: prefs)
        #expect(result.suggestions.contains { $0.contains("気分を記録") })
    }

    @Test("週次インサイトが生成される")
    func generateWeeklyInsight() {
        let entries = (0..<7).map { i in
            LifeLogEntry(
                timestamp: Date().addingTimeInterval(TimeInterval(-86400 * i)),
                entryType: .manual,
                title: "Day \(i)",
                tags: ["朝活"]
            )
        }
        let result = engine.generateWeeklyInsight(entries: entries, weekStart: Date())
        #expect(!result.summaryText.isEmpty)
        #expect(result.summaryText.contains("7件"))
    }

    @Test("気分トレンドの分析: データ不足")
    func moodTrendInsufficientData() {
        let entry = LifeLogEntry(entryType: .mood, title: "1件のみ", moodScore: .good)
        let result = engine.generateWeeklyInsight(entries: [entry], weekStart: Date())
        #expect(result.moodTrend == "データ不足")
    }

    @Test("気分トレンドの分析: 安定")
    func moodTrendStable() {
        let entries = [
            LifeLogEntry(entryType: .mood, title: "1", moodScore: .good),
            LifeLogEntry(entryType: .mood, title: "2", moodScore: .good),
            LifeLogEntry(entryType: .mood, title: "3", moodScore: .good),
            LifeLogEntry(entryType: .mood, title: "4", moodScore: .good),
        ]
        let result = engine.generateWeeklyInsight(entries: entries, weekStart: Date())
        #expect(result.moodTrend == "安定")
    }

    @Test("パターン検出: エントリー数が少ないとパターンなし")
    func detectPatternsEmpty() {
        let patterns = engine.detectPatterns(entries: [])
        #expect(patterns.isEmpty)
    }

    @Test("パターン検出: タグパターンが検出される")
    func detectTagPattern() {
        let entries = (0..<5).map { _ in
            LifeLogEntry(entryType: .manual, title: "test", tags: ["朝活"])
        }
        let patterns = engine.detectPatterns(entries: entries)
        #expect(patterns.contains { $0.patternType == "frequent_tags" })
    }

    @Test("パターン検出: 時間帯パターンが検出される")
    func detectTimePattern() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 8
        let fixedDate = calendar.date(from: components)!

        let entries = (0..<5).map { i in
            LifeLogEntry(
                timestamp: fixedDate.addingTimeInterval(TimeInterval(i * 60)),
                entryType: .manual,
                title: "test \(i)"
            )
        }
        let patterns = engine.detectPatterns(entries: entries)
        #expect(patterns.contains { $0.patternType == "time_pattern" })
    }
}

// MARK: - ExportService Tests

@Suite("ExportService", .tags(.service))
@MainActor
struct ExportServiceTests {
    let exportService = ExportService()

    @Test("JSON エクスポートが成功する")
    func exportJSON() throws {
        let entry = LifeLogEntry(entryType: .manual, title: "テスト記録", moodScore: .good)
        let data = try exportService.exportAsJSON(entries: [entry])
        #expect(!data.isEmpty)

        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("テスト記録"))
    }

    @Test("JSON エクスポートが空配列でも成功する")
    func exportJSONEmpty() throws {
        let data = try exportService.exportAsJSON(entries: [])
        #expect(!data.isEmpty)
        // prettyPrinted なので改行付き空配列
        let json = String(data: data, encoding: .utf8)!
        #expect(json.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("["))
        #expect(json.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("]"))
    }

    @Test("CSV エクスポートが成功する")
    func exportCSV() throws {
        let entry = LifeLogEntry(entryType: .manual, title: "テスト記録", moodScore: .good)
        let data = try exportService.exportAsCSV(entries: [entry])
        let csv = String(data: data, encoding: .utf8)!

        // ヘッダー行を確認
        #expect(csv.contains("日時,種別,タイトル"))
        // データ行を確認
        #expect(csv.contains("テスト記録"))
        #expect(csv.contains("手動記録"))
        #expect(csv.contains("良い"))
    }

    @Test("CSV エクスポートがカンマを含む値を正しくエスケープする")
    func exportCSVEscape() throws {
        let entry = LifeLogEntry(entryType: .manual, title: "テスト,記録")
        let data = try exportService.exportAsCSV(entries: [entry])
        let csv = String(data: data, encoding: .utf8)!
        #expect(csv.contains("\"テスト,記録\""))
    }

    @Test("CSV エクスポートがお気に入り状態を表示する")
    func exportCSVFavorite() throws {
        let entry = LifeLogEntry(entryType: .manual, title: "お気に入り")
        entry.isFavorite = true
        let data = try exportService.exportAsCSV(entries: [entry])
        let csv = String(data: data, encoding: .utf8)!
        #expect(csv.contains("はい"))
    }
}

// MARK: - TimelineService Tests

@Suite("TimelineService", .tags(.service))
@MainActor
struct TimelineServiceTests {
    let timelineService = TimelineService()

    @Test("buildTimeline が日付でフィルタしてソートする")
    func buildTimeline() async throws {
        let mockDataService = MockDataService()
        let now = Date()
        let entry1 = LifeLogEntry(timestamp: now.addingTimeInterval(-3600), title: "1時間前")
        let entry2 = LifeLogEntry(timestamp: now, title: "今")
        mockDataService.entries = [entry1, entry2]

        let result = try await timelineService.buildTimeline(for: now, dataService: mockDataService)
        // 新しい順にソートされているはず
        #expect(result.first?.title == "今")
    }

    @Test("refreshFromAllSources が全エントリーを保存する")
    func refreshFromAllSources() async throws {
        let mockDataService = MockDataService()
        let healthEntry = LifeLogEntry(entryType: .health, title: "歩数", source: .healthKit)
        let locationEntry = LifeLogEntry(entryType: .location, title: "場所", source: .coreLocation)

        try await timelineService.refreshFromAllSources(
            dataService: mockDataService,
            healthEntries: [healthEntry],
            locationEntries: [locationEntry],
            photoEntries: [],
            activityEntries: []
        )

        #expect(mockDataService.entries.count == 2)
        #expect(mockDataService.saveEntryCalled == true)
    }
}

// MARK: - DailySummaryGenerator Tests

@Suite("DailySummaryGenerator", .tags(.service))
@MainActor
struct DailySummaryGeneratorTests {
    @Test("日次サマリーが正しく生成される")
    func generateSummary() {
        let mockEngine = MockInsightsEngine()
        let generator = DailySummaryGenerator(insightsEngine: mockEngine)

        let entries = [
            LifeLogEntry(entryType: .manual, title: "朝の記録", moodScore: .great),
            LifeLogEntry(entryType: .mood, title: "気分", moodScore: .good),
            LifeLogEntry(entryType: .photo, title: "写真"),
        ]

        let summary = generator.generate(entries: entries, date: Date(), preferences: UserPreferences())
        #expect(summary.entryCount == 3)
        #expect(summary.photoCount == 1)
    }

    @Test("気分平均が正しく計算される")
    func moodAverageCalculation() {
        let mockEngine = MockInsightsEngine()
        let generator = DailySummaryGenerator(insightsEngine: mockEngine)

        let entries = [
            LifeLogEntry(entryType: .mood, title: "1", moodScore: .great),  // 5
            LifeLogEntry(entryType: .mood, title: "2", moodScore: .good),   // 4
            LifeLogEntry(entryType: .mood, title: "3", moodScore: .neutral), // 3
        ]

        let summary = generator.generate(entries: entries, date: Date(), preferences: UserPreferences())
        let expected = (5.0 + 4.0 + 3.0) / 3.0
        #expect(abs((summary.moodAverage ?? 0) - expected) < 0.0001)
    }

    @Test("ヘルスケアデータが正しく集計される")
    func healthDataAggregation() {
        let mockEngine = MockInsightsEngine()
        let generator = DailySummaryGenerator(insightsEngine: mockEngine)

        let stepsEntry = LifeLogEntry(
            entryType: .health, title: "歩数",
            source: .healthKit, healthMetricTypeRawValue: "steps", healthMetricValue: 5000
        )
        let sleepEntry = LifeLogEntry(
            entryType: .health, title: "睡眠",
            source: .healthKit, healthMetricTypeRawValue: "sleep", healthMetricValue: 7.5
        )

        let summary = generator.generate(
            entries: [stepsEntry, sleepEntry],
            date: Date(),
            preferences: UserPreferences()
        )
        #expect(summary.totalSteps == 5000)
        #expect(abs((summary.sleepHours ?? 0) - 7.5) < 0.0001)
    }

    @Test("訪問場所がユニークに集計される")
    func visitedPlacesUnique() {
        let mockEngine = MockInsightsEngine()
        let generator = DailySummaryGenerator(insightsEngine: mockEngine)

        let entries = [
            LifeLogEntry(entryType: .location, title: "場所1", locationName: "渋谷"),
            LifeLogEntry(entryType: .location, title: "場所2", locationName: "渋谷"),
            LifeLogEntry(entryType: .location, title: "場所3", locationName: "新宿"),
        ]

        let summary = generator.generate(entries: entries, date: Date(), preferences: UserPreferences())
        #expect(summary.visitedPlaces.count == 2)
    }
}

// MARK: - WeeklySummaryGenerator Tests

@Suite("WeeklySummaryGenerator", .tags(.service))
@MainActor
struct WeeklySummaryGeneratorTests {
    @Test("週次サマリーが正しく生成される")
    func generateSummary() {
        let mockEngine = MockInsightsEngine()
        let generator = WeeklySummaryGenerator(insightsEngine: mockEngine)

        let entries = (0..<7).map { i in
            LifeLogEntry(entryType: .manual, title: "Day \(i)", moodScore: .good)
        }

        let weekStart = Date()
        let summary = generator.generate(entries: entries, weekStartDate: weekStart)
        #expect(summary.entryCount == 7)
    }

    @Test("前週との比較テキストが生成される")
    func comparisonText() {
        let mockEngine = MockInsightsEngine()
        let generator = WeeklySummaryGenerator(insightsEngine: mockEngine)

        let current = (0..<5).map { _ in LifeLogEntry(entryType: .manual, title: "今週") }
        let previous = (0..<3).map { _ in LifeLogEntry(entryType: .manual, title: "先週") }

        let summary = generator.generate(
            entries: current,
            weekStartDate: Date(),
            previousWeekEntries: previous
        )
        #expect(summary.comparisonWithPreviousWeek?.contains("2件増えました") == true)
    }

    @Test("前週データがないと比較テキストは nil")
    func noComparisonWithoutPrevious() {
        let mockEngine = MockInsightsEngine()
        let generator = WeeklySummaryGenerator(insightsEngine: mockEngine)

        let summary = generator.generate(entries: [], weekStartDate: Date())
        #expect(summary.comparisonWithPreviousWeek == nil)
    }
}

// MARK: - Tags

extension Tag {
    @Tag static var service: Self
}
