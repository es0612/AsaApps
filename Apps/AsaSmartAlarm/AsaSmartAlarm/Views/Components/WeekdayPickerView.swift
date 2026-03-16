//
//  WeekdayPickerView.swift
//  AsaSmartAlarm
//
//  曜日選択コンポーネント
//

import SwiftUI
import AsaUIKit

// MARK: - 曜日選択ビュー

/// アラームの繰り返し曜日を選択するビュー
struct WeekdayPickerView: View {
    // MARK: - Properties

    @Binding var selectedDays: [Int]

    private let dayNames = ["日", "月", "火", "水", "木", "金", "土"]

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { dayIndex in
                DayButton(
                    dayName: dayNames[dayIndex],
                    isSelected: selectedDays.contains(dayIndex),
                    isWeekend: dayIndex == 0 || dayIndex == 6
                ) {
                    toggleDay(dayIndex)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.removeAll { $0 == day }
        } else {
            selectedDays.append(day)
            selectedDays.sort()
        }
    }
}

// MARK: - 日ボタン

private struct DayButton: View {
    let dayName: String
    let isSelected: Bool
    let isWeekend: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(dayName)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 36, height: 36)
                .foregroundStyle(foregroundColor)
                .background(backgroundColor)
                .clipShape(Circle())
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isWeekend {
            return .red.opacity(0.7)
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return AsaColors.coffeeBrown
        } else {
            return Color(.systemGray6)
        }
    }
}

// MARK: - プリセットボタン

/// よく使う繰り返しパターンのプリセット
struct WeekdayPresetButtons: View {
    @Binding var selectedDays: [Int]

    var body: some View {
        HStack(spacing: 12) {
            PresetButton(title: "平日", days: [1, 2, 3, 4, 5], selectedDays: $selectedDays)
            PresetButton(title: "週末", days: [0, 6], selectedDays: $selectedDays)
            PresetButton(title: "毎日", days: [0, 1, 2, 3, 4, 5, 6], selectedDays: $selectedDays)
            PresetButton(title: "なし", days: [], selectedDays: $selectedDays)
        }
        .font(.caption)
    }
}

private struct PresetButton: View {
    let title: String
    let days: [Int]
    @Binding var selectedDays: [Int]

    private var isActive: Bool {
        selectedDays.sorted() == days.sorted()
    }

    var body: some View {
        Button(action: {
            selectedDays = days
        }) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? AsaColors.coffeeBrown : Color(.systemGray5))
                .foregroundStyle(isActive ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview("曜日選択") {
    struct PreviewWrapper: View {
        @State private var selectedDays: [Int] = [1, 2, 3, 4, 5]

        var body: some View {
            VStack(spacing: 20) {
                WeekdayPickerView(selectedDays: $selectedDays)

                Divider()

                WeekdayPresetButtons(selectedDays: $selectedDays)

                Text("選択中: \(selectedDays.map { String($0) }.joined(separator: ", "))")
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
