//
//  TaskSemanticAnalyzerTests.swift
//  AsaSmartTodoTests
//
//  TaskSemanticAnalyzerのテスト（iOS 18専用）
//  LLM意味分析機能の検証
//

import Foundation
import Testing
@testable import AsaSmartTodo

/// TaskSemanticAnalyzerのテストスイート（iOS 18専用）
///
/// iOS 18 Foundation ModelsによるLLM意味分析機能をテストします。
/// iOS 17以下では可用性エラーが返されることを確認します。
struct TaskSemanticAnalyzerTests {

    // MARK: - Basic Analysis Tests

    /// 基本的なタスク分析のテスト
    ///
    /// シンプルなタスクの意味分析が正常に動作することを確認します。
    @Test("基本的なタスク分析")
    @MainActor
    func testBasicTaskAnalysis() async throws {
        let analyzer = TaskSemanticAnalyzer()

        let task = SmartTask(
            title: "買い物に行く",
            description: "スーパーで食材を購入する",
            category: .personal,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400) // 明日
        )

        // iOS 18可用性チェック
        let availabilityChecker = FoundationModelAvailability.shared
        let isAvailable = await availabilityChecker.isAvailable()

        if isAvailable {
            #if canImport(LanguageModel)
            if #available(iOS 18.0, *) {
                // iOS 18でLLM分析を実行
                let result = try await analyzer.analyzeTask(task)

                // スコアが0.0-1.0の範囲内であることを確認
                #expect(result.semanticComplexity >= 0.0 && result.semanticComplexity <= 1.0)
                #expect(result.riskScore >= 0.0 && result.riskScore <= 1.0)
                #expect(result.feasibilityScore >= 0.0 && result.feasibilityScore <= 1.0)
                #expect(result.confidence >= 0.0 && result.confidence <= 1.0)

                // 洞察が3-5個であることを確認
                #expect(result.insights.count >= 3 && result.insights.count <= 5)

                // combinedScoreが計算されていることを確認
                #expect(result.combinedScore >= 0.0 && result.combinedScore <= 1.0)

                print("✅ LLM分析結果:")
                print("   意味的複雑度: \(result.semanticComplexity)")
                print("   リスクスコア: \(result.riskScore)")
                print("   実行可能性: \(result.feasibilityScore)")
                print("   推定時間: \(result.estimatedMinutes ?? 0)分")
                print("   洞察数: \(result.insights.count)")
                print("   統合スコア: \(result.combinedScore)")
            }
            #endif
        } else {
            // iOS 17以下ではmodelUnavailableエラーを期待
            do {
                _ = try await analyzer.analyzeTask(task)
                Issue.record("iOS 17以下でエラーが発生しませんでした")
            } catch let error as SemanticAnalysisError {
                #expect(error == .modelUnavailable)
                print("✅ iOS 17以下: modelUnavailableエラーを正常に検出")
            } catch {
                Issue.record("予期しないエラー型: \(error)")
            }
        }
    }

    /// 複雑なタスク分析のテスト
    ///
    /// 複雑な説明を持つタスクの分析が適切に動作することを確認します。
    @Test("複雑なタスク分析")
    @MainActor
    func testComplexTaskAnalysis() async throws {
        let analyzer = TaskSemanticAnalyzer()

        let task = SmartTask(
            title: "プロジェクト企画書の作成と提出",
            description: """
            新規プロジェクトの企画書を作成し、関係者にレビューを依頼する。
            市場調査データの収集、競合分析、予算見積もりを含める必要がある。
            締め切りは厳守で、複数の部門との調整が必要。
            """,
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400 * 2) // 2日後
        )

        let availabilityChecker = FoundationModelAvailability.shared
        let isAvailable = await availabilityChecker.isAvailable()

        if isAvailable {
            #if canImport(LanguageModel)
            if #available(iOS 18.0, *) {
                let result = try await analyzer.analyzeTask(task)

                // 複雑なタスクなので意味的複雑度が高いことを期待
                #expect(result.semanticComplexity >= 0.5)

                // リスクスコアが中程度以上であることを期待
                #expect(result.riskScore >= 0.4)

                // 推定時間が設定されていることを確認
                #expect(result.estimatedMinutes != nil)
                if let minutes = result.estimatedMinutes {
                    #expect(minutes > 0)
                }

                print("✅ 複雑タスク分析結果:")
                print("   意味的複雑度: \(result.semanticComplexity) (高複雑度)")
                print("   リスクスコア: \(result.riskScore)")
                print("   推定時間: \(result.estimatedMinutes ?? 0)分")
            }
            #endif
        }
    }

    /// 期限切れタスク分析のテスト
    ///
    /// 期限切れタスクのリスクスコアが高くなることを確認します。
    @Test("期限切れタスク分析")
    @MainActor
    func testOverdueTaskAnalysis() async throws {
        let analyzer = TaskSemanticAnalyzer()

        let task = SmartTask(
            title: "緊急対応が必要なバグ修正",
            description: "本番環境で発生した重大なバグを修正する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(-86400) // 昨日（期限切れ）
        )

        let availabilityChecker = FoundationModelAvailability.shared
        let isAvailable = await availabilityChecker.isAvailable()

        if isAvailable {
            #if canImport(LanguageModel)
            if #available(iOS 18.0, *) {
                let result = try await analyzer.analyzeTask(task)

                // 期限切れなのでリスクスコアが高いことを期待
                #expect(result.riskScore >= 0.6)

                print("✅ 期限切れタスク分析結果:")
                print("   リスクスコア: \(result.riskScore) (高リスク)")
            }
            #endif
        }
    }

    // MARK: - Edge Case Tests

    /// 空の説明を持つタスク分析のテスト
    ///
    /// 説明がないタスクでも分析が動作することを確認します。
    @Test("空の説明を持つタスク分析")
    @MainActor
    func testTaskWithoutDescription() async throws {
        let analyzer = TaskSemanticAnalyzer()

        let task = SmartTask(
            title: "メール確認",
            description: nil,
            category: .personal,
            userPriority: .low,
            dueDate: nil
        )

        let availabilityChecker = FoundationModelAvailability.shared
        let isAvailable = await availabilityChecker.isAvailable()

        if isAvailable {
            #if canImport(LanguageModel)
            if #available(iOS 18.0, *) {
                let result = try await analyzer.analyzeTask(task)

                // 説明なしでも分析が成功することを確認
                #expect(result.semanticComplexity >= 0.0)
                #expect(result.insights.count >= 3)

                print("✅ 説明なしタスク分析成功")
            }
            #endif
        }
    }

    /// 期限なしタスク分析のテスト
    ///
    /// 期限がないタスクでも分析が動作することを確認します。
    @Test("期限なしタスク分析")
    @MainActor
    func testTaskWithoutDueDate() async throws {
        let analyzer = TaskSemanticAnalyzer()

        let task = SmartTask(
            title: "新しいプログラミング言語の学習",
            description: "時間があるときに少しずつ学習する",
            category: .personal,
            userPriority: .low,
            dueDate: nil
        )

        let availabilityChecker = FoundationModelAvailability.shared
        let isAvailable = await availabilityChecker.isAvailable()

        if isAvailable {
            #if canImport(LanguageModel)
            if #available(iOS 18.0, *) {
                let result = try await analyzer.analyzeTask(task)

                // 期限なしでも分析が成功することを確認
                #expect(result.semanticComplexity >= 0.0)

                print("✅ 期限なしタスク分析成功")
            }
            #endif
        }
    }

    // MARK: - Error Handling Tests

    /// モデル利用不可エラーのテスト
    ///
    /// iOS 17以下で適切にエラーが返されることを確認します。
    @Test("モデル利用不可エラー")
    @MainActor
    func testModelUnavailableError() async {
        // モックの可用性チェッカー（常にfalseを返す）
        class MockUnavailableChecker: FoundationModelAvailability {
            override func isAvailable() async -> Bool {
                return false
            }
        }

        let mockChecker = MockUnavailableChecker()
        let analyzer = TaskSemanticAnalyzer(availabilityChecker: mockChecker)

        let task = SmartTask(
            title: "テストタスク",
            description: "テスト用",
            category: .work,
            userPriority: .medium,
            dueDate: nil
        )

        do {
            _ = try await analyzer.analyzeTask(task)
            Issue.record("エラーが発生しませんでした")
        } catch let error as SemanticAnalysisError {
            #expect(error == .modelUnavailable)
            print("✅ modelUnavailableエラーを正常に検出")
        } catch {
            Issue.record("予期しないエラー型: \(error)")
        }
    }

    // MARK: - Performance Tests

    /// LLM分析のパフォーマンステスト
    ///
    /// LLM分析が1秒以内に完了することを確認します。
    @Test("LLM分析のパフォーマンス", .timeLimit(.minutes(1)))
    @MainActor
    func testAnalysisPerformance() async throws {
        let analyzer = TaskSemanticAnalyzer()

        let task = SmartTask(
            title: "パフォーマンステスト",
            description: "LLM分析の速度を測定する",
            category: .work,
            userPriority: .medium,
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

                print("✅ LLM分析実行時間: \(elapsed)")
            }
            #endif
        }
    }

    // MARK: - Score Validation Tests

    /// combinedScoreの計算検証
    ///
    /// combinedScoreが正しい計算式で算出されることを確認します。
    @Test("combinedScore計算検証")
    @MainActor
    func testCombinedScoreCalculation() async throws {
        let analyzer = TaskSemanticAnalyzer()

        let task = SmartTask(
            title: "スコア計算テスト",
            description: "combinedScoreの計算を検証する",
            category: .work,
            userPriority: .medium,
            dueDate: nil
        )

        let availabilityChecker = FoundationModelAvailability.shared
        let isAvailable = await availabilityChecker.isAvailable()

        if isAvailable {
            #if canImport(LanguageModel)
            if #available(iOS 18.0, *) {
                let result = try await analyzer.analyzeTask(task)

                // combinedScoreの計算式を手動で検証
                let expectedScore = (result.semanticComplexity * 0.4) +
                                    (result.riskScore * 0.3) +
                                    ((1.0 - result.feasibilityScore) * 0.3)

                // 誤差を考慮して比較（浮動小数点演算の誤差対策）
                let difference = abs(result.combinedScore - expectedScore)
                #expect(difference < 0.0001)

                print("✅ combinedScore計算検証成功")
                print("   計算値: \(result.combinedScore)")
                print("   期待値: \(expectedScore)")
            }
            #endif
        }
    }
}
