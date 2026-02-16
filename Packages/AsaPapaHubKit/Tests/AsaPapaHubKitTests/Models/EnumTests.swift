import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("Enum テスト")
struct EnumTests {
    // MARK: - LifeDomain

    @Test("LifeDomain - 全ケース数")
    func testLifeDomainCaseCount() {
        #expect(LifeDomain.allCases.count == 6)
    }

    @Test("LifeDomain - rawValue")
    func testLifeDomainRawValues() {
        #expect(LifeDomain.morning.rawValue == "morning")
        #expect(LifeDomain.health.rawValue == "health")
        #expect(LifeDomain.family.rawValue == "family")
        #expect(LifeDomain.finance.rawValue == "finance")
        #expect(LifeDomain.community.rawValue == "community")
        #expect(LifeDomain.learning.rawValue == "learning")
    }

    @Test("LifeDomain - displayName")
    func testLifeDomainDisplayName() {
        #expect(LifeDomain.morning.displayName == "朝活")
        #expect(LifeDomain.health.displayName == "健康")
        #expect(LifeDomain.family.displayName == "家族")
        #expect(LifeDomain.finance.displayName == "資産")
        #expect(LifeDomain.community.displayName == "地域")
        #expect(LifeDomain.learning.displayName == "学習")
    }

    @Test("LifeDomain - icon")
    func testLifeDomainIcon() {
        #expect(LifeDomain.morning.icon == "sunrise.fill")
        #expect(LifeDomain.health.icon == "heart.fill")
        #expect(LifeDomain.learning.icon == "book.fill")
    }

    @Test("LifeDomain - emoji")
    func testLifeDomainEmoji() {
        #expect(LifeDomain.morning.emoji == "☀️")
        #expect(LifeDomain.family.emoji == "👨‍👩‍👧")
    }

    @Test("LifeDomain - accentColorHex")
    func testLifeDomainAccentColor() {
        #expect(LifeDomain.morning.accentColorHex == "#FF9500")
        #expect(LifeDomain.health.accentColorHex == "#FF2D55")
    }

    // MARK: - RoutineItemStatus

    @Test("RoutineItemStatus - 全ケース数")
    func testRoutineItemStatusCaseCount() {
        #expect(RoutineItemStatus.allCases.count == 4)
    }

    @Test("RoutineItemStatus - displayName と icon")
    func testRoutineItemStatusProperties() {
        #expect(RoutineItemStatus.pending.displayName == "未着手")
        #expect(RoutineItemStatus.inProgress.displayName == "進行中")
        #expect(RoutineItemStatus.completed.displayName == "完了")
        #expect(RoutineItemStatus.skipped.displayName == "スキップ")
        #expect(RoutineItemStatus.completed.icon == "checkmark.circle.fill")
    }

    // MARK: - TrendDirection

    @Test("TrendDirection - isPositive")
    func testTrendDirectionIsPositive() {
        #expect(TrendDirection.up.isPositive == true)
        #expect(TrendDirection.down.isPositive == false)
        #expect(TrendDirection.stable.isPositive == true)
    }

    @Test("TrendDirection - displayName と icon")
    func testTrendDirectionProperties() {
        #expect(TrendDirection.up.displayName == "上昇")
        #expect(TrendDirection.up.icon == "arrow.up.right")
        #expect(TrendDirection.down.icon == "arrow.down.right")
        #expect(TrendDirection.stable.icon == "arrow.right")
    }

    // MARK: - BriefingStatus

    @Test("BriefingStatus - 全ケースのプロパティ")
    func testBriefingStatusProperties() {
        #expect(BriefingStatus.pending.displayName == "待機中")
        #expect(BriefingStatus.generating.displayName == "生成中")
        #expect(BriefingStatus.completed.icon == "checkmark.circle")
        #expect(BriefingStatus.failed.icon == "exclamationmark.triangle")
    }

    // MARK: - ChartPeriod

    @Test("ChartPeriod - dayCount")
    func testChartPeriodDayCount() {
        #expect(ChartPeriod.day.dayCount == 1)
        #expect(ChartPeriod.week.dayCount == 7)
        #expect(ChartPeriod.month.dayCount == 30)
    }

    @Test("ChartPeriod - calendarComponent")
    func testChartPeriodCalendarComponent() {
        #expect(ChartPeriod.day.calendarComponent == .day)
        #expect(ChartPeriod.week.calendarComponent == .weekOfYear)
        #expect(ChartPeriod.month.calendarComponent == .month)
    }
}
