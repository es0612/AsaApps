//
//  InteractiveWidgetButtons.swift
//  PapaHubWidgetExtension
//
//  Widget内のインタラクティブボタン
//  AppIntentを使用したルーティンアイテム完了ボタン
//

import SwiftUI
import WidgetKit
import AppIntents

// MARK: - InteractiveWidgetButtons

/// ウィジェット内のインタラクティブボタンコンポーネント
struct InteractiveWidgetButtons: View {
    let routineItems: [RoutineItemData]

    private let coffeeBrown = Color(red: 0.776, green: 0.549, blue: 0.325)
    private let darkSlate = Color(red: 0.184, green: 0.243, blue: 0.275)

    var body: some View {
        VStack(spacing: 6) {
            ForEach(routineItems.filter { !$0.isCompleted }) { item in
                Button(intent: CompleteRoutineItemIntent(itemId: item.id)) {
                    HStack(spacing: 8) {
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundStyle(coffeeBrown)

                        Image(systemName: item.icon)
                            .font(.caption2)
                            .foregroundStyle(coffeeBrown)

                        Text(item.title)
                            .font(.caption)
                            .foregroundStyle(darkSlate)

                        Spacer()

                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
