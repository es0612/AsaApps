import AsaSmartReminderKit
import AsaUIKit
import SwiftUI

// MARK: - リマインダーカード

struct ReminderCardView: View {
    let reminder: LocationReminder
    let onToggle: () -> Void

    var body: some View {
        AsaCard {
            HStack(spacing: 12) {
                // 完了チェック
                Button(action: onToggle) {
                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(reminder.isCompleted ? .green : AsaColors.mutedSage)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                        .strikethrough(reminder.isCompleted)
                        .foregroundStyle(reminder.isCompleted ? .secondary : .primary)

                    if let note = reminder.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        if let location = reminder.location {
                            Label {
                                Text(location.name)
                            } icon: {
                                Image(systemName: location.category.systemImageName)
                            }
                            .font(.caption2)
                            .foregroundStyle(AsaColors.coffeeBrown)
                        }

                        Label(reminder.triggerDescription, systemImage: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(AsaColors.mutedSage)

                        if reminder.isRepeating {
                            Label("繰り返し", systemImage: "repeat")
                                .font(.caption2)
                                .foregroundStyle(AsaColors.mutedSage)
                        }
                    }
                }

                Spacer()

                if reminder.triggerCount > 0 {
                    Text("\(reminder.triggerCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(6)
                        .background(AsaColors.softCream)
                        .clipShape(Circle())
                }
            }
        }
    }
}
