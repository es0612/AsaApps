import SwiftUI
import AsaLifeLogKit

// MARK: - TimelineFilterBar

/// タイムラインの日付・ソースフィルタバー
struct TimelineFilterBar: View {
    @Binding var selectedDate: Date
    @Binding var selectedSource: DataSource?
    var onDateChanged: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // 日付ピッカー
            DatePicker(
                "日付",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .onChange(of: selectedDate) {
                onDateChanged()
            }

            // ソースフィルタ
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "すべて",
                        isSelected: selectedSource == nil
                    ) {
                        selectedSource = nil
                    }

                    ForEach(DataSource.allCases, id: \.self) { source in
                        FilterChip(
                            title: source.displayName,
                            isSelected: selectedSource == source
                        ) {
                            selectedSource = source
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - FilterChip

/// フィルタ選択チップ
private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
