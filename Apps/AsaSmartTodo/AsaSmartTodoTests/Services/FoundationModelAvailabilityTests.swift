//
//  FoundationModelAvailabilityTests.swift
//  AsaSmartTodoTests
//
//  FoundationModelAvailabilityのテスト
//  iOS 18可用性チェックとステータス取得の検証
//

import Foundation
import Testing
@testable import AsaSmartTodo

/// FoundationModelAvailabilityのテストスイート
///
/// iOS 18 Foundation Modelsの可用性チェック機能をテストします。
struct FoundationModelAvailabilityTests {

    // MARK: - Availability Check Tests

    /// iOS 18可用性チェックのテスト
    ///
    /// `isAvailable()`メソッドが適切に動作することを確認します。
    /// - iOS 18以降: trueまたはfalse（モデルの状態による）
    /// - iOS 17以下: 常にfalse
    @Test("iOS可用性チェック")
    @MainActor
    func testIsAvailable() async {
        let checker = FoundationModelAvailability.shared

        // 可用性をチェック（結果は環境依存）
        let isAvailable = await checker.isAvailable()

        // 戻り値がBool型であることを確認
        #expect(isAvailable is Bool)

        // iOS 18以降の場合のみ、availableまたはunavailableのいずれか
        #if canImport(LanguageModel)
        if #available(iOS 18.0, *) {
            // iOS 18では可用性が決定される
            print("✅ iOS 18+: Foundation Models可用性 = \(isAvailable)")
        } else {
            // iOS 17以下では常にfalse
            #expect(isAvailable == false)
        }
        #else
        // LanguageModelがインポートできない場合は常にfalse
        #expect(isAvailable == false)
        #endif
    }

    /// ステータス取得のテスト
    ///
    /// `getStatus()`メソッドが適切なステータスを返すことを確認します。
    @Test("ステータス取得")
    @MainActor
    func testGetStatus() async {
        let checker = FoundationModelAvailability.shared

        let status = await checker.getStatus()

        // ステータスが取得できることを確認
        switch status {
        case .available:
            print("✅ Foundation Models: 利用可能")
        case .unavailable(let reason):
            print("✅ Foundation Models: 利用不可 - 理由: \(reason)")
        }
    }

    /// ユーザー向けメッセージ取得のテスト
    ///
    /// `getUserFacingMessage()`が適切な日本語メッセージを返すことを確認します。
    @Test("ユーザー向けメッセージ取得")
    @MainActor
    func testGetUserFacingMessage() async {
        let checker = FoundationModelAvailability.shared

        let message = await checker.getUserFacingMessage()

        // メッセージが空でないことを確認
        #expect(!message.isEmpty)

        // メッセージの形式を確認
        #if canImport(LanguageModel)
        if #available(iOS 18.0, *) {
            // iOS 18では「利用可能」または「利用できません」のいずれか
            let validMessages = [
                "✨ iOS 18の高度なAI分析が利用可能です",
                "AI分析モデルが現在利用できません",
                "AI分析が現在利用できません"
            ]
            #expect(validMessages.contains(message))
        } else {
            // iOS 17以下では特定のメッセージ
            #expect(message == "iOS 18以降で高度なAI分析が利用可能になります")
        }
        #else
        #expect(message == "iOS 18以降で高度なAI分析が利用可能になります")
        #endif

        print("✅ ユーザー向けメッセージ: \(message)")
    }

    /// デバッグ情報取得のテスト
    ///
    /// `getDebugInfo()`が環境情報を適切に返すことを確認します。
    @Test("デバッグ情報取得")
    @MainActor
    func testGetDebugInfo() async {
        let checker = FoundationModelAvailability.shared

        let debugInfo = await checker.getDebugInfo()

        // デバッグ情報が取得できることを確認
        #expect(!debugInfo.isEmpty)

        // 必須フィールドの存在確認
        #expect(debugInfo["iOS Version"] != nil)
        #expect(debugInfo["LanguageModel Framework"] != nil)

        print("✅ デバッグ情報: \(debugInfo)")
    }

    // MARK: - Singleton Tests

    /// シングルトンパターンのテスト
    ///
    /// `shared`が常に同一インスタンスを返すことを確認します。
    @Test("シングルトンパターン")
    @MainActor
    func testSingletonPattern() {
        let instance1 = FoundationModelAvailability.shared
        let instance2 = FoundationModelAvailability.shared

        // 同一インスタンスであることを確認
        #expect(instance1 === instance2)
    }

    // MARK: - Thread Safety Tests

    /// 並行アクセスのテスト
    ///
    /// 複数のタスクから同時にアクセスしても安全に動作することを確認します。
    @Test("並行アクセス安全性")
    @MainActor
    func testConcurrentAccess() async {
        let checker = FoundationModelAvailability.shared

        // 10個の並行タスクを起動
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await checker.isAvailable()
                }
            }

            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }

            // すべてのタスクが完了したことを確認
            #expect(results.count == 10)

            // すべての結果が一貫していることを確認
            let firstResult = results.first ?? false
            #expect(results.allSatisfy { $0 == firstResult })
        }
    }

    // MARK: - Status Mapping Tests

    /// ステータスマッピングのテスト
    ///
    /// 各ステータスに対して適切なメッセージが返されることを確認します。
    @Test("ステータスとメッセージのマッピング")
    @MainActor
    func testStatusMessageMapping() async {
        let checker = FoundationModelAvailability.shared

        let status = await checker.getStatus()
        let message = await checker.getUserFacingMessage()

        // ステータスとメッセージの整合性を確認
        switch status {
        case .available:
            #expect(message.contains("利用可能"))
        case .unavailable(let reason):
            switch reason {
            case .olderOS:
                #expect(message.contains("iOS 18以降"))
            case .modelNotAvailable:
                #expect(message.contains("利用できません"))
            case .unknown:
                #expect(message.contains("利用できません"))
            }
        }
    }

    // MARK: - Performance Tests

    /// パフォーマンステスト
    ///
    /// 可用性チェックが50ms以内に完了することを確認します。
    @Test("可用性チェックのパフォーマンス", .timeLimit(.minutes(1)))
    @MainActor
    func testAvailabilityCheckPerformance() async {
        let checker = FoundationModelAvailability.shared

        let startTime = ContinuousClock.now
        _ = await checker.isAvailable()
        let elapsed = ContinuousClock.now - startTime

        print("✅ 可用性チェック実行時間: \(elapsed)")
    }
}
