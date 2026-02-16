import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - ルーティンアイテム行

/// 個別のルーティンアイテムの表示行
struct RoutineItemRow: View {
    let item: MorningRoutineItem
    let onComplete: () -> Void
    let onSkip: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // ステータスアイコン
            statusIcon

            // アイテム情報
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(item.status == .completed)
                    .foregroundStyle(item.status == .completed ? .secondary : .primary)

                Text("目安: \(item.estimatedMinutes)分")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // アクションボタン
            if item.status == .pending || item.status == .inProgress {
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onSkip()
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.quaternary))
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onComplete()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(AsaColors.coffeeBrown))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        )
    }

    // MARK: - Private

    private var statusIcon: some View {
        Image(systemName: item.status.icon)
            .font(.title3)
            .foregroundStyle(statusColor)
            .frame(width: 32)
    }

    private var statusColor: Color {
        switch item.status {
        case .pending: AsaColors.mutedSage
        case .inProgress: .orange
        case .completed: .green
        case .skipped: .gray
        }
    }
}
