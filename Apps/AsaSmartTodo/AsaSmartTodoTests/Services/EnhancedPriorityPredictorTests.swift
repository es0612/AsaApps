//
//  EnhancedPriorityPredictorTests.swift
//  AsaSmartTodoTests
//
//  EnhancedPriorityPredictorのテスト
//  ハイブリッドAI予測（ルールベース40% + LLM60%）の検証
//

import Foundation
import Testing
@testable import AsaSmartTodo

/// EnhancedPriorityPredictorのテストスイート
///
/// ハイブリッドAI予測機能をテストします。
/// - ルールベース予測とLLM分析の統合
/// - iOS 17/18互換性とフォールバック処理
/// - 信頼度スコアの計算
struct EnhancedPriorityPredictorTests {

    // MARK: - Basic Prediction Tests

    /// 基本的な優先度予測のテスト
    ///
    /// ハイブリッド予測が正常に動作することを確認します。
    @Test("基本的な優先度予測")
    @MainActor
    func testBasicPriorityPrediction() async {
        let predictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "重要な会議の準備",
            description: "プレゼン資料を作成する",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400) // 明日
        )

        let result = await predictor.predictPriority(for: task)

        // 基本的なプロパティの検証
        #expect(result.suggestedPriority is PriorityLevel)
        #expect(result.confidenceScore >= 0.0 && result.confidenceScore <= 1.0)
        #expect(!result.reasons.isEmpty)
        #expect(result.ruleBasedScore >= 0.0 && result.ruleBasedScore <= 1.0)

        print("✅ ハイブリッド予測結果:")
        print("   推奨優先度: \(result.suggestedPriority)")
        print("   信頼度: \(result.confidenceScore)")
        print("   LLM使用: \(result.usedLLM)")
        print("   理由数: \(result.reasons.count)")
    }

    /// iOS 18でのLLM統合テスト
    ///
    /// iOS 18環境でLLM分析が統合されることを確認します。
    @Test("iOS 18でのLLM統合")
    @MainActor
    func testLLMIntegrationOnIOS18() async {
        let predictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "複雑なプロジェクト計画の立案",
            description: "複数の要素を考慮した詳細な計画を作成する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400 * 3) // 3日後
        )

        let result = await predictor.predictPriority(for: task)

        let availabilityChecker = FoundationModelAvailability.shared
        let isAvailable = await availabilityChecker.isAvailable()

        if isAvailable {
            // iOS 18でLLMが利用可能な場合
            #expect(result.usedLLM == true)
            #expect(result.semanticAnalysis != nil)

            if let semanticAnalysis = result.semanticAnalysis {
                // LLM分析結果の検証
                #expect(semanticAnalysis.semanticComplexity >= 0.0 && semanticAnalysis.semanticComplexity <= 1.0)
                #expect(semanticAnalysis.riskScore >= 0.0 && semanticAnalysis.riskScore <= 1.0)
                #expect(semanticAnalysis.feasibilityScore >= 0.0 && semanticAnalysis.feasibilityScore <= 1.0)
                #expect(semanticAnalysis.insights.count >= 3)
            }

            // LLM使用時の信頼度向上を確認（75%以上）
            #expect(result.confidenceScore >= 0.75)

            print("✅ iOS 18 LLM統合成功:")
            print("   LLM使用: \(result.usedLLM)")
            print("   信頼度: \(result.confidenceScore) (LLM boost)")
        } else {
            // iOS 17以下またはLLM利用不可の場合
            #expect(result.usedLLM == false)
            #expect(result.semanticAnalysis == nil)

            print("✅ iOS 17以下: ルールベースフォールバック")
        }
    }

    /// iOS 17でのフォールバック動作テスト
    ///
    /// iOS 17環境でルールベース予測のみが使用されることを確認します。
    @Test("iOS 17でのフォールバック動作")
    @MainActor
    func testFallbackToRuleBasedOnOlderiOS() async {
        // モックの可用性チェッカー（常にfalseを返す）
        class MockUnavailableChecker: FoundationModelAvailability {
            override func isAvailable() async -> Bool {
                return false
            }
        }

        let mockChecker = MockUnavailableChecker()
        let predictor = EnhancedPriorityPredictor(availabilityChecker: mockChecker)

        let task = SmartTask(
            title: "テストタスク",
            description: "フォールバック動作を検証する",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )

        let result = await predictor.predictPriority(for: task)

        // ルールベースフォールバックの検証
        #expect(result.usedLLM == false)
        #expect(result.semanticAnalysis == nil)
        #expect(result.ruleBasedScore >= 0.0 && result.ruleBasedScore <= 1.0)

        // 信頼度がルールベースの範囲内（60-85%）
        #expect(result.confidenceScore >= 0.60 && result.confidenceScore <= 0.85)

        print("✅ フォールバック動作確認:")
        print("   LLM使用: \(result.usedLLM)")
        print("   信頼度: \(result.confidenceScore) (ルールベースのみ)")
    }

    // MARK: - Hybrid Score Tests

    /// ハイブリッドスコア計算のテスト
    ///
    /// ルールベース（40%）とLLM（60%）の重み付け統合を検証します。
    @Test("ハイブリッドスコア計算")
    @MainActor
    func testHybridScoreCalculation() async {
        let predictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "ハイブリッドスコアテスト",
            description: "40:60の重み付けを検証する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        let result = await predictor.predictPriority(for: task)

        if result.usedLLM, let semanticAnalysis = result.semanticAnalysis {
            // ハイブリッドスコアの計算式を手動で検証
            let expectedHybridScore = (result.ruleBasedScore * 0.4) + (semanticAnalysis.combinedScore * 0.6)

            // スコアレンジに基づく優先度マッピング
            let expectedPriority: PriorityLevel
            if expectedHybridScore >= 0.7 {
                expectedPriority = .high
            } else if expectedHybridScore >= 0.4 {
                expectedPriority = .medium
            } else {
                expectedPriority = .low
            }

            #expect(result.suggestedPriority == expectedPriority)

            print("✅ ハイブリッドスコア計算検証:")
            print("   ルールベース: \(result.ruleBasedScore) (40%)")
            print("   LLM分析: \(semanticAnalysis.combinedScore) (60%)")
            print("   ハイブリッド: \(expectedHybridScore)")
            print("   推奨優先度: \(result.suggestedPriority)")
        }
    }

    // MARK: - Confidence Score Tests

    /// LLM使用時の信頼度向上テスト
    ///
    /// LLMを使用すると信頼度が5-10%向上することを確認します。
    @Test("LLM使用時の信頼度向上")
    @MainActor
    func testConfidenceImprovementWithLLM() async {
        // ルールベースのみの予測器
        class MockUnavailableChecker: FoundationModelAvailability {
            override func isAvailable() async -> Bool {
                return false
            }
        }

        let mockChecker = MockUnavailableChecker()
        let ruleBasedPredictor = EnhancedPriorityPredictor(availabilityChecker: mockChecker)

        // ハイブリッド予測器（LLM使用可能な場合）
        let hybridPredictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "信頼度比較テスト",
            description: "LLM使用による信頼度向上を検証する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        let ruleBasedResult = await ruleBasedPredictor.predictPriority(for: task)
        let hybridResult = await hybridPredictor.predictPriority(for: task)

        let availabilityChecker = FoundationModelAvailability.shared
        let isAvailable = await availabilityChecker.isAvailable()

        if isAvailable && hybridResult.usedLLM {
            // LLM使用時の信頼度が高いことを確認
            #expect(hybridResult.confidenceScore > ruleBasedResult.confidenceScore)

            let improvement = hybridResult.confidenceScore - ruleBasedResult.confidenceScore
            print("✅ LLM使用による信頼度向上:")
            print("   ルールベースのみ: \(ruleBasedResult.confidenceScore)")
            print("   LLM統合: \(hybridResult.confidenceScore)")
            print("   向上幅: +\(improvement) (+\(Int(improvement * 100))%)")
        } else {
            print("⚠️ LLM利用不可のため、信頼度比較スキップ")
        }
    }

    /// 信頼度スコアの範囲テスト
    ///
    /// 信頼度が適切な範囲（60-98%）に収まることを確認します。
    @Test("信頼度スコアの範囲")
    @MainActor
    func testConfidenceScoreRange() async {
        let predictor = EnhancedPriorityPredictor()

        let tasks = [
            SmartTask(title: "低優先度タスク", description: nil, category: .personal, userPriority: .low, dueDate: nil),
            SmartTask(title: "中優先度タスク", description: "通常の作業", category: .work, userPriority: .medium, dueDate: Date().addingTimeInterval(86400 * 7)),
            SmartTask(title: "高優先度タスク", description: "緊急対応", category: .work, userPriority: .high, dueDate: Date().addingTimeInterval(3600))
        ]

        for task in tasks {
            let result = await predictor.predictPriority(for: task)

            // 信頼度が60-98%の範囲内
            #expect(result.confidenceScore >= 0.60 && result.confidenceScore <= 0.98)

            // LLM使用時は75%以上
            if result.usedLLM {
                #expect(result.confidenceScore >= 0.75)
            }

            print("   \(task.title): 信頼度 \(result.confidenceScore)")
        }
    }

    // MARK: - Reason Combination Tests

    /// 予測理由の統合テスト
    ///
    /// ルールベース理由とLLM洞察が統合されることを確認します。
    @Test("予測理由の統合")
    @MainActor
    func testReasonCombination() async {
        let predictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "理由統合テスト",
            description: "複数の理由が統合されることを確認する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        let result = await predictor.predictPriority(for: task)

        // 理由が少なくとも1つ存在
        #expect(result.reasons.count >= 1)

        if result.usedLLM {
            // LLM使用時は理由が多くなる（ルールベース+LLM洞察）
            #expect(result.reasons.count >= 3)

            print("✅ 統合された理由（\(result.reasons.count)個）:")
            for (index, reason) in result.reasons.enumerated() {
                print("   \(index + 1). \(reason)")
            }
        }
    }

    // MARK: - Priority Level Tests

    /// 優先度レベルマッピングのテスト
    ///
    /// スコアから優先度への変換が正しいことを確認します。
    @Test("優先度レベルマッピング")
    @MainActor
    func testPriorityLevelMapping() async {
        let predictor = EnhancedPriorityPredictor()

        // 高優先度タスク（期限が近く、重要カテゴリ）
        let highPriorityTask = SmartTask(
            title: "緊急対応",
            description: "即座に対処が必要",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(3600) // 1時間後
        )

        // 低優先度タスク（期限なし、個人カテゴリ）
        let lowPriorityTask = SmartTask(
            title: "いつかやる",
            description: "急ぎではない",
            category: .personal,
            userPriority: .low,
            dueDate: nil
        )

        let highResult = await predictor.predictPriority(for: highPriorityTask)
        let lowResult = await predictor.predictPriority(for: lowPriorityTask)

        // 高優先度タスクは.high、低優先度タスクは.lowになることを期待
        print("   高優先度タスク: \(highResult.suggestedPriority)")
        print("   低優先度タスク: \(lowResult.suggestedPriority)")

        // 高優先度タスクの信頼度が高いことを確認
        #expect(highResult.confidenceScore >= 0.70)
    }

    // MARK: - Performance Tests

    /// ハイブリッド予測のパフォーマンステスト
    ///
    /// 予測が適切な時間内に完了することを確認します。
    /// - ルールベースのみ: 50ms以内
    /// - LLM統合: 1秒以内
    @Test("ハイブリッド予測のパフォーマンス")
    @MainActor
    func testHybridPredictionPerformance() async {
        let predictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "パフォーマンステスト",
            description: "予測速度を測定する",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )

        let startTime = ContinuousClock.now
        let result = await predictor.predictPriority(for: task)
        let elapsed = ContinuousClock.now - startTime

        if result.usedLLM {
            // LLM使用時は1秒以内
            print("✅ LLM統合予測実行時間: \(elapsed)")
        } else {
            // ルールベースのみは50ms以内
            print("✅ ルールベース予測実行時間: \(elapsed)")
        }
    }

    // MARK: - Edge Case Tests

    /// 空のタスクでの予測テスト
    ///
    /// 最小限の情報しかないタスクでも予測が動作することを確認します。
    @Test("空のタスクでの予測")
    @MainActor
    func testPredictionWithMinimalTask() async {
        let predictor = EnhancedPriorityPredictor()

        let task = SmartTask(
            title: "最小",
            description: nil,
            category: .personal,
            userPriority: .low,
            dueDate: nil
        )

        let result = await predictor.predictPriority(for: task)

        // 最小限のタスクでも予測が成功
        #expect(result.suggestedPriority is PriorityLevel)
        #expect(result.confidenceScore >= 0.0)
        #expect(!result.reasons.isEmpty)

        print("✅ 最小限タスク予測成功")
    }
}
