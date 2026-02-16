//
//  QuickEntryIntent.swift
//  AsaPapaHub
//
//  クイック記録用App Intent
//  Siri: 「AsaPapaHub で記録して」
//

import AppIntents
import SwiftData
import AsaPapaHubKit

// MARK: - QuickEntryIntent

/// クイック記録を行う App Intent
struct QuickEntryIntent: AppIntent {
    static let title: LocalizedStringResource = "クイック記録"
    static let description: IntentDescription = IntentDescription("パパハブにクイック記録を追加します")

    @Parameter(title: "内容")
    var content: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: QuickAction.self)
        let context = container.mainContext

        let action = QuickAction(
            title: content,
            iconName: "plus.circle",
            domainRawValue: LifeDomain.morning.rawValue,
            actionTypeRawValue: "quick_entry"
        )

        context.insert(action)
        try context.save()

        return .result(dialog: "「\(content)」を記録しました！")
    }
}

// CompleteRoutineItemIntent は Shared/SharedIntents.swift に定義
