import Testing
@testable import AsaLifeLogKit

// MARK: - EntryType Tests

@Suite("EntryType Enum")
struct EntryTypeTests {
    @Test("全ケースが6件存在する")
    func allCases() {
        #expect(EntryType.allCases.count == 6)
    }

    @Test("rawValue が正しい")
    func rawValues() {
        #expect(EntryType.manual.rawValue == "manual")
        #expect(EntryType.health.rawValue == "health")
        #expect(EntryType.location.rawValue == "location")
        #expect(EntryType.photo.rawValue == "photo")
        #expect(EntryType.activity.rawValue == "activity")
        #expect(EntryType.mood.rawValue == "mood")
    }

    @Test("displayName が日本語で表示される")
    func displayNames() {
        #expect(EntryType.manual.displayName == "手動記録")
        #expect(EntryType.health.displayName == "ヘルスケア")
        #expect(EntryType.location.displayName == "位置情報")
        #expect(EntryType.photo.displayName == "写真")
        #expect(EntryType.activity.displayName == "アクティビティ")
        #expect(EntryType.mood.displayName == "気分")
    }

    @Test("icon が SF Symbol 名を返す")
    func icons() {
        #expect(EntryType.manual.icon == "pencil.and.list.clipboard")
        #expect(EntryType.health.icon == "heart.fill")
        #expect(EntryType.photo.icon == "photo.fill")
    }
}

// MARK: - MoodScore Tests

@Suite("MoodScore Enum")
struct MoodScoreTests {
    @Test("全ケースが5件存在する")
    func allCases() {
        #expect(MoodScore.allCases.count == 5)
    }

    @Test("numericValue が1〜5の範囲")
    func numericValues() {
        #expect(MoodScore.terrible.numericValue == 1)
        #expect(MoodScore.bad.numericValue == 2)
        #expect(MoodScore.neutral.numericValue == 3)
        #expect(MoodScore.good.numericValue == 4)
        #expect(MoodScore.great.numericValue == 5)
    }

    @Test("displayName が日本語で表示される")
    func displayNames() {
        #expect(MoodScore.terrible.displayName == "最悪")
        #expect(MoodScore.neutral.displayName == "普通")
        #expect(MoodScore.great.displayName == "最高")
    }

    @Test("emoji が正しい絵文字を返す")
    func emojis() {
        #expect(MoodScore.terrible.emoji == "😫")
        #expect(MoodScore.bad.emoji == "😟")
        #expect(MoodScore.neutral.emoji == "😐")
        #expect(MoodScore.good.emoji == "😊")
        #expect(MoodScore.great.emoji == "😄")
    }

    @Test("rawValue からの復元が正しい")
    func rawValueInit() {
        #expect(MoodScore(rawValue: "good") == .good)
        #expect(MoodScore(rawValue: "invalid") == nil)
    }
}

// MARK: - ActivityType Tests

@Suite("ActivityType Enum")
struct ActivityTypeTests {
    @Test("全ケースが5件存在する")
    func allCases() {
        #expect(ActivityType.allCases.count == 5)
    }

    @Test("rawValue が正しい")
    func rawValues() {
        #expect(ActivityType.stationary.rawValue == "stationary")
        #expect(ActivityType.walking.rawValue == "walking")
        #expect(ActivityType.running.rawValue == "running")
        #expect(ActivityType.cycling.rawValue == "cycling")
        #expect(ActivityType.driving.rawValue == "driving")
    }

    @Test("displayName が日本語で表示される")
    func displayNames() {
        #expect(ActivityType.walking.displayName == "徒歩")
        #expect(ActivityType.running.displayName == "ランニング")
        #expect(ActivityType.cycling.displayName == "自転車")
    }

    @Test("icon が SF Symbol 名を返す")
    func icons() {
        #expect(ActivityType.stationary.icon == "figure.stand")
        #expect(ActivityType.walking.icon == "figure.walk")
        #expect(ActivityType.running.icon == "figure.run")
        #expect(ActivityType.cycling.icon == "bicycle")
        #expect(ActivityType.driving.icon == "car.fill")
    }
}

// MARK: - DataSource Tests

@Suite("DataSource Enum")
struct DataSourceTests {
    @Test("全ケースが5件存在する")
    func allCases() {
        #expect(DataSource.allCases.count == 5)
    }

    @Test("rawValue が正しい")
    func rawValues() {
        #expect(DataSource.manual.rawValue == "manual")
        #expect(DataSource.healthKit.rawValue == "healthKit")
        #expect(DataSource.coreLocation.rawValue == "coreLocation")
        #expect(DataSource.photoLibrary.rawValue == "photoLibrary")
        #expect(DataSource.coreMotion.rawValue == "coreMotion")
    }

    @Test("displayName が日本語で表示される")
    func displayNames() {
        #expect(DataSource.manual.displayName == "手動入力")
        #expect(DataSource.healthKit.displayName == "ヘルスケア")
        #expect(DataSource.coreLocation.displayName == "位置情報")
    }
}

// MARK: - PlaceCategory Tests

@Suite("PlaceCategory Enum")
struct PlaceCategoryTests {
    @Test("全ケースが7件存在する")
    func allCases() {
        #expect(PlaceCategory.allCases.count == 7)
    }

    @Test("displayName が日本語で表示される")
    func displayNames() {
        #expect(PlaceCategory.home.displayName == "自宅")
        #expect(PlaceCategory.work.displayName == "職場")
        #expect(PlaceCategory.restaurant.displayName == "飲食店")
        #expect(PlaceCategory.shop.displayName == "お店")
        #expect(PlaceCategory.park.displayName == "公園")
        #expect(PlaceCategory.gym.displayName == "ジム")
        #expect(PlaceCategory.other.displayName == "その他")
    }

    @Test("icon が SF Symbol 名を返す")
    func icons() {
        #expect(PlaceCategory.home.icon == "house.fill")
        #expect(PlaceCategory.work.icon == "building.2.fill")
        #expect(PlaceCategory.restaurant.icon == "fork.knife")
    }

    @Test("rawValue からの復元が正しい")
    func rawValueInit() {
        #expect(PlaceCategory(rawValue: "home") == .home)
        #expect(PlaceCategory(rawValue: "invalid") == nil)
    }
}

// MARK: - ChartPeriod Tests

@Suite("ChartPeriod Enum")
struct ChartPeriodTests {
    @Test("全ケースが4件存在する")
    func allCases() {
        #expect(ChartPeriod.allCases.count == 4)
    }

    @Test("displayName が日本語で表示される")
    func displayNames() {
        #expect(ChartPeriod.week.displayName == "1週間")
        #expect(ChartPeriod.month.displayName == "1ヶ月")
        #expect(ChartPeriod.threeMonths.displayName == "3ヶ月")
        #expect(ChartPeriod.year.displayName == "1年")
    }

    @Test("dayCount が正しい日数を返す")
    func dayCounts() {
        #expect(ChartPeriod.week.dayCount == 7)
        #expect(ChartPeriod.month.dayCount == 30)
        #expect(ChartPeriod.threeMonths.dayCount == 90)
        #expect(ChartPeriod.year.dayCount == 365)
    }

    @Test("rawValue からの復元が正しい")
    func rawValueInit() {
        #expect(ChartPeriod(rawValue: "week") == .week)
        #expect(ChartPeriod(rawValue: "threeMonths") == .threeMonths)
        #expect(ChartPeriod(rawValue: "invalid") == nil)
    }
}
