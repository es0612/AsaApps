//
//  SharedIntents.swift
//  AsaPapaHub
//
//  アプリとWidget間で共有するApp Intents
//

import AppIntents

// MARK: - CompleteRoutineItemIntent

/// ルーティンアイテムを完了するApp Intent（Widget用）
struct CompleteRoutineItemIntent: AppIntent {
    static let title: LocalizedStringResource = "ルーティンアイテム完了"
    static let description: IntentDescription = IntentDescription("ルーティンアイテムを完了にします")

    @Parameter(title: "アイテムID")
    var itemId: String?

    init() {}

    init(itemId: String) {
        self.itemId = itemId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
