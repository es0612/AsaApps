import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("DomainAggregatorService テスト")
struct DomainAggregatorServiceTests {
    @Test("スナップショット集約 - データあり")
    @MainActor func testAggregateWithData() async throws {
        let dataService = MockHubDataService()
        let snapshot = DomainSnapshot(domainRawValue: "health", score: 80, summary: "良好")
        dataService.snapshots = [snapshot]
        let aggregator = DomainAggregatorService(dataService: dataService)
        let results = try await aggregator.aggregateSnapshots(for: Date())
        #expect(results.count == 1)
        #expect(results.first?.domain == .health)
    }

    @Test("スナップショット集約 - データなし（デフォルト生成）")
    @MainActor func testAggregateWithoutData() async throws {
        let dataService = MockHubDataService()
        let aggregator = DomainAggregatorService(dataService: dataService)
        let results = try await aggregator.aggregateSnapshots(for: Date())
        #expect(results.count == LifeDomain.allCases.count)
        for snapshot in results {
            #expect(snapshot.score == 0)
        }
    }

    @Test("週間データ集約")
    @MainActor func testAggregateWeeklyData() async throws {
        let dataService = MockHubDataService()
        let today = Date()
        let snapshot1 = DomainSnapshot(date: today, domainRawValue: "health", score: 80)
        let snapshot2 = DomainSnapshot(date: today, domainRawValue: "morning", score: 90)
        dataService.snapshots = [snapshot1, snapshot2]
        let aggregator = DomainAggregatorService(dataService: dataService)
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        let results = try await aggregator.aggregateWeeklyData(from: weekAgo, to: today)
        #expect(!results.isEmpty)
    }

    @Test("集約 - エラー伝播")
    @MainActor func testAggregateError() async {
        let dataService = MockHubDataService()
        dataService.shouldThrowError = true
        let aggregator = DomainAggregatorService(dataService: dataService)
        do {
            _ = try await aggregator.aggregateSnapshots(for: Date())
            #expect(Bool(false), "エラーが発生するべき")
        } catch {
            #expect(error is PapaHubError)
        }
    }

    @Test("デフォルトスナップショットのサマリー")
    @MainActor func testDefaultSnapshotSummary() async throws {
        let dataService = MockHubDataService()
        let aggregator = DomainAggregatorService(dataService: dataService)
        let results = try await aggregator.aggregateSnapshots(for: Date())
        for snapshot in results {
            #expect(snapshot.summary.contains("データがありません"))
        }
    }

    @Test("デフォルトスナップショットのトレンド")
    @MainActor func testDefaultSnapshotTrend() async throws {
        let dataService = MockHubDataService()
        let aggregator = DomainAggregatorService(dataService: dataService)
        let results = try await aggregator.aggregateSnapshots(for: Date())
        for snapshot in results {
            #expect(snapshot.trend == .stable)
        }
    }

    @Test("週間データ - 空の結果")
    @MainActor func testWeeklyDataEmpty() async throws {
        let dataService = MockHubDataService()
        let aggregator = DomainAggregatorService(dataService: dataService)
        let today = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        let results = try await aggregator.aggregateWeeklyData(from: weekAgo, to: today)
        #expect(results.isEmpty)
    }

    @Test("週間データ - 複数日")
    @MainActor func testWeeklyDataMultipleDays() async throws {
        let dataService = MockHubDataService()
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let s1 = DomainSnapshot(date: today, domainRawValue: "health", score: 80)
        let s2 = DomainSnapshot(date: yesterday, domainRawValue: "health", score: 70)
        dataService.snapshots = [s1, s2]
        let aggregator = DomainAggregatorService(dataService: dataService)
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        let results = try await aggregator.aggregateWeeklyData(from: twoDaysAgo, to: today)
        let healthData = results[.health]
        #expect(healthData?.count == 2)
    }

    @Test("デフォルトスナップショット - 全ドメイン")
    @MainActor func testDefaultSnapshotsAllDomains() async throws {
        let dataService = MockHubDataService()
        let aggregator = DomainAggregatorService(dataService: dataService)
        let results = try await aggregator.aggregateSnapshots(for: Date())
        let domains = Set(results.map(\.domain))
        for domain in LifeDomain.allCases {
            #expect(domains.contains(domain))
        }
    }

    @Test("週間エラー伝播")
    @MainActor func testWeeklyAggregateError() async {
        let dataService = MockHubDataService()
        dataService.shouldThrowError = true
        let aggregator = DomainAggregatorService(dataService: dataService)
        let today = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        do {
            _ = try await aggregator.aggregateWeeklyData(from: weekAgo, to: today)
            #expect(Bool(false), "エラーが発生するべき")
        } catch {
            #expect(error is PapaHubError)
        }
    }
}
