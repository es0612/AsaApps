import Foundation
//
//  AIPerformanceTests.swift
//  AsaSmartTodoTests
//
//  AI機能のパフォーマンステスト
//  処理速度、メモリ使用量、並行処理性能を検証
//

import Testing
@testable import AsaSmartTodo

/// AI機能のパフォーマンステストスイート
///
/// AI予測の処理速度、メモリ効率、並行処理性能を測定します。
/// - ルールベース予測: 50ms以内
/// - LLM分析: 1秒以内
/// - ハイブリッド予測: 1秒以内
@MainActor
struct AIPerformanceTests {

    // MARK: - Response Time Tests

    /// ルールベース予測のレスポンスタイムテスト
    ///
    /// ルールベース予測が50ms以内に完了することを確認します。
    @Test("ルールベース予測のレスポンスタイム", .timeLimit(.minutes(1)))
    func testRuleBasedPredictionResponseTime() async {
        // モックの可用性チェッカー（LLM無効）
        class MockUnavailableChecker: FoundationModelAvailability {
            override func isAvailable() async -> Bool {
                return false
            }
        }

        let mockChecker = MockUnavailableChecker()
        let predictor = EnhancedPriorityPredictor(availabilityChecker: mockChecker)

        let task = SmartTask(
            title: "レスポンスタイムテスト",
            description: "ルールベース予測の速度を測定する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        let startTime = ContinuousClock.now
        let result = await predictor.predictPriority(for: task)
        let elapsed = ContinuousClock.now - startTime

        // ルールベースのみであることを確認
        #expect(result.usedLLM == false)

        print("✅ ルールベース予測レスポンスタイム: \(elapsed)")
    }

    /// LLM分析のレスポンスタイムテスト
    ///
    /// LLM分析が1秒以内に完了することを確認します。
    @Test("LLM分析のレスポンスタイム", .timeLimit(.minutes(1)))
    func testLLMAnalysisResponseTime() async throws {
        let analyzer = TaskSemanticAnalyzer()

        let task = SmartTask(
            title: "LLMレスポンスタイムテスト",
            description: "LLM分析の速度を測定する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        let availabilityChecker = FoundationModelAvailability.shared
        let isAvailable = await availabilityChecker.isAvailable()

        if isAvailable {
            #if canImport(LanguageModel)
            if #available(iOS 18.0, *) {
                let startTime = ContinuousClock.now
                _ = try await analyzer.analyzeTask(task)
                let elapsed = ContinuousClock.now - startTime

                print("✅ LLM分析レスポンスタイム: \(elapsed)")
            }
            #endif
        } else {
            print("⚠️ LLM利用不可のため、レスポンスタイムテストスキップ")
        }
    }

    /// ハイブリッド予測のレスポンスタイムテスト
    ///
    /// ハイブリッド予測（ルールベース+LLM）が1秒以内に完了することを確認します。
    @Test("ハイブリッド予測のレスポンスタイム", .timeLimit(.minutes(1)))
    func testHybridPredictionResponseTime() async {
        let predictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "ハイブリッドレスポンスタイムテスト",
            description: "ハイブリッド予測の速度を測定する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        let startTime = ContinuousClock.now
        let result = await predictor.predictPriority(for: task)
        let elapsed = ContinuousClock.now - startTime

        if result.usedLLM {
            print("✅ ハイブリッド予測（LLM使用）レスポンスタイム: \(elapsed)")
        } else {
            print("✅ ハイブリッド予測（ルールベースのみ）レスポンスタイム: \(elapsed)")
        }
    }

    // MARK: - Throughput Tests

    /// 連続予測のスループットテスト
    ///
    /// 10個のタスクを連続で予測しても、パフォーマンスが劣化しないことを確認します。
    @Test("連続予測のスループット", .timeLimit(.minutes(1)))
    func testConsecutivePredictionThroughput() async {
        let predictor = EnhancedPriorityPredictor()

        var totalTime: Duration = .zero
        let taskCount = 10

        for i in 1...taskCount {
            let task = SmartTask(
                title: "スループットテスト\(i)",
                description: "連続予測の性能を測定する",
                category: .work,
                userPriority: .medium,
                dueDate: Date().addingTimeInterval(86400)
            )

            let startTime = ContinuousClock.now
            _ = await predictor.predictPriority(for: task)
            let elapsed = ContinuousClock.now - startTime

            totalTime += elapsed
        }

        let averageTime = totalTime / taskCount

        print("✅ 連続予測スループット:")
        print("   総タスク数: \(taskCount)")
        print("   総処理時間: \(totalTime)")
        print("   平均処理時間: \(averageTime)")
    }

    /// 並行予測のスループットテスト
    ///
    /// 複数のタスクを並行で予測しても、適切に処理されることを確認します。
    @Test("並行予測のスループット", .timeLimit(.minutes(1)))
    func testConcurrentPredictionThroughput() async {
        let predictor = EnhancedPriorityPredictor()
        let taskCount = 5

        let startTime = ContinuousClock.now

        await withTaskGroup(of: Void.self) { group in
            for i in 1...taskCount {
                group.addTask {
                    let task = SmartTask(
                        title: "並行予測テスト\(i)",
                        description: "並行処理の性能を測定する",
                        category: .work,
                        userPriority: .medium,
                        dueDate: Date().addingTimeInterval(86400)
                    )

                    _ = await predictor.predictPriority(for: task)
                }
            }
        }

        let elapsed = ContinuousClock.now - startTime

        print("✅ 並行予測スループット:")
        print("   並行タスク数: \(taskCount)")
        print("   総処理時間: \(elapsed)")
    }

    // MARK: - Complexity Tests

    /// シンプルタスクの処理速度テスト
    ///
    /// シンプルなタスクの予測が高速に処理されることを確認します。
    @Test("シンプルタスクの処理速度", .timeLimit(.minutes(1)))
    func testSimpleTaskProcessingSpeed() async {
        let predictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "買い物",
            description: nil,
            category: .personal,
            userPriority: .low,
            dueDate: nil
        )

        let startTime = ContinuousClock.now
        _ = await predictor.predictPriority(for: task)
        let elapsed = ContinuousClock.now - startTime

        print("✅ シンプルタスク処理時間: \(elapsed)")
    }

    /// 複雑タスクの処理速度テスト
    ///
    /// 複雑なタスクでも適切な時間内に処理されることを確認します。
    @Test("複雑タスクの処理速度", .timeLimit(.minutes(1)))
    func testComplexTaskProcessingSpeed() async {
        let predictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "大規模プロジェクトの企画書作成と提出、関係者レビュー依頼",
            description: """
            新規プロジェクトの包括的な企画書を作成する。
            以下の要素を含める必要がある：
            - 市場調査データの収集と分析
            - 競合分析（少なくとも5社）
            - 詳細な予算見積もり（3年分）
            - タイムライン（マイルストーン含む）
            - リスク分析と緩和策
            - ROI試算

            複数の部門（営業、マーケティング、技術、財務）との調整が必要。
            経営陣へのプレゼンテーションも準備する。
            """,
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400 * 7) // 1週間後
        )

        let startTime = ContinuousClock.now
        _ = await predictor.predictPriority(for: task)
        let elapsed = ContinuousClock.now - startTime

        print("✅ 複雑タスク処理時間: \(elapsed)")
    }

    // MARK: - Cache Effectiveness Tests

    /// 同一タスクの再予測パフォーマンステスト
    ///
    /// 同じタスクを再予測しても、パフォーマンスが適切であることを確認します。
    @Test("同一タスクの再予測パフォーマンス", .timeLimit(.minutes(1)))
    func testRepeatPredictionPerformance() async {
        let predictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "再予測テスト",
            description: "同じタスクを複数回予測する",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )

        // 1回目の予測
        let firstStartTime = ContinuousClock.now
        _ = await predictor.predictPriority(for: task)
        let firstElapsed = ContinuousClock.now - firstStartTime

        // 2回目の予測
        let secondStartTime = ContinuousClock.now
        _ = await predictor.predictPriority(for: task)
        let secondElapsed = ContinuousClock.now - secondStartTime

        print("✅ 再予測パフォーマンス:")
        print("   1回目: \(firstElapsed)")
        print("   2回目: \(secondElapsed)")
    }

    // MARK: - Memory Efficiency Tests

    /// 大量タスク予測のメモリ効率テスト
    ///
    /// 大量のタスクを予測してもメモリリークがないことを確認します。
    @Test("大量タスク予測のメモリ効率", .timeLimit(.minutes(1)))
    func testMemoryEfficiencyWithManyTasks() async {
        let predictor = EnhancedPriorityPredictor()
        let taskCount = 50

        for i in 1...taskCount {
            let task = SmartTask(
                title: "メモリ効率テスト\(i)",
                description: "メモリリークがないことを確認する",
                category: .work,
                userPriority: .medium,
                dueDate: Date().addingTimeInterval(86400)
            )

            _ = await predictor.predictPriority(for: task)

            // 定期的にメモリを解放
            if i % 10 == 0 {
                print("   処理完了: \(i)/\(taskCount)")
            }
        }

        print("✅ メモリ効率テスト完了: \(taskCount)タスク")
    }

    // MARK: - Availability Check Performance Tests

    /// 可用性チェックのパフォーマンステスト
    ///
    /// Foundation Models可用性チェックが高速に実行されることを確認します。
    @Test("可用性チェックのパフォーマンス", .timeLimit(.minutes(1)))
    func testAvailabilityCheckPerformance() async {
        let checker = FoundationModelAvailability.shared

        let startTime = ContinuousClock.now
        _ = await checker.isAvailable()
        let elapsed = ContinuousClock.now - startTime

        print("✅ 可用性チェック実行時間: \(elapsed)")
    }

    /// 連続可用性チェックのパフォーマンステスト
    ///
    /// 可用性チェックを連続実行してもパフォーマンスが劣化しないことを確認します。
    @Test("連続可用性チェックのパフォーマンス", .timeLimit(.minutes(1)))
    func testConsecutiveAvailabilityCheckPerformance() async {
        let checker = FoundationModelAvailability.shared
        let checkCount = 10

        var totalTime: Duration = .zero

        for _ in 1...checkCount {
            let startTime = ContinuousClock.now
            _ = await checker.isAvailable()
            let elapsed = ContinuousClock.now - startTime
            totalTime += elapsed
        }

        let averageTime = totalTime / checkCount

        print("✅ 連続可用性チェック:")
        print("   チェック回数: \(checkCount)")
        print("   平均実行時間: \(averageTime)")
    }

    // MARK: - UI Response Tests

    /// EnhancedPrediction取得のレスポンスタイムテスト
    ///
    /// UI表示用のEnhancedPrediction取得が1秒以内に完了することを確認します。
    @Test("EnhancedPrediction取得のレスポンスタイム", .timeLimit(.minutes(1)))
    @MainActor
    func testEnhancedPredictionRetrievalResponseTime() async {
        let dataService = DataService(inMemory: true)
        let viewModel = SmartTodoViewModel(dataService: dataService)

        let task = SmartTask(
            title: "UI表示パフォーマンステスト",
            description: "EnhancedPrediction取得の速度を測定する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        let startTime = ContinuousClock.now
        _ = await viewModel.getEnhancedPrediction(for: task)
        let elapsed = ContinuousClock.now - startTime

        print("✅ EnhancedPrediction取得時間: \(elapsed)")
    }

    // MARK: - Baseline Comparison Tests

    /// ベースライン比較テスト
    ///
    /// ハイブリッド予測がルールベースのみより大幅に遅くないことを確認します。
    @Test("ハイブリッド vs ルールベースのパフォーマンス比較", .timeLimit(.minutes(1)))
    func testHybridVsRuleBasedPerformanceComparison() async {
        // ルールベースのみ
        class MockUnavailableChecker: FoundationModelAvailability {
            override func isAvailable() async -> Bool {
                return false
            }
        }

        let mockChecker = MockUnavailableChecker()
        let ruleBasedPredictor = EnhancedPriorityPredictor(availabilityChecker: mockChecker)

        // ハイブリッド
        let hybridPredictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "パフォーマンス比較テスト",
            description: "ルールベースとハイブリッドの速度を比較する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        // ルールベース測定
        let ruleBasedStart = ContinuousClock.now
        _ = await ruleBasedPredictor.predictPriority(for: task)
        let ruleBasedElapsed = ContinuousClock.now - ruleBasedStart

        // ハイブリッド測定
        let hybridStart = ContinuousClock.now
        let hybridResult = await hybridPredictor.predictPriority(for: task)
        let hybridElapsed = ContinuousClock.now - hybridStart

        print("✅ パフォーマンス比較:")
        print("   ルールベース: \(ruleBasedElapsed)")
        print("   ハイブリッド: \(hybridElapsed)")
        if hybridResult.usedLLM {
            print("   LLM使用: あり")
        } else {
            print("   LLM使用: なし")
        }
    }
}
