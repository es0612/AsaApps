import SwiftUI
import AsaUIKit

struct AddHabitView: View {
    let viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var habitName = ""
    @State private var habitDescription = ""
    @State private var selectedCategory = HabitCategory.health
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "AsaCoffeeBrown"
    @State private var selectedFrequency = TargetFrequency.daily
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()

    private let availableIcons = [
        "star.fill", "heart.fill", "book.fill", "figure.run",
        "brain.head.profile", "drop.fill", "moon.fill", "sun.max.fill",
        "pencil", "music.note", "gamecontroller.fill", "cup.and.saucer.fill",
        "leaf.fill", "globe", "bicycle", "dumbbell.fill"
    ]

    private let availableColors = [
        "AsaCoffeeBrown", "AsaMocha", "AsaSoftCream",
        "AsaDarkSlate", "AsaMutedSage"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // 基本情報セクション
                Section("基本情報") {
                    TextField("習慣名", text: $habitName)

                    TextField("説明（任意）", text: $habitDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                // カテゴリセクション
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(HabitCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // アイコンとカラーセクション
                Section("アイコンとカラー") {
                    // アイコン選択
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .white : AsaColors.darkSlate)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? AsaColors.coffeeBrown : AsaColors.softCream)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // カラー選択
                    HStack(spacing: 16) {
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? AsaColors.darkSlate : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }

                // 頻度セクション
                Section("頻度") {
                    Picker("目標頻度", selection: $selectedFrequency) {
                        ForEach(TargetFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue)
                                .tag(frequency)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // リマインダーセクション
                Section("リマインダー") {
                    Toggle("リマインダーを設定", isOn: $reminderEnabled)

                    if reminderEnabled {
                        DatePicker(
                            "時刻",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                // プレビューセクション
                Section("プレビュー") {
                    HStack(spacing: 16) {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundColor(Color(selectedColor))
                            .frame(width: 50, height: 50)
                            .background(Color(selectedColor).opacity(0.1))
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(habitName.isEmpty ? "習慣名" : habitName)
                                .font(.headline)
                                .foregroundColor(AsaColors.darkSlate)

                            Text(selectedCategory.rawValue)
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)

                            Text(selectedFrequency.rawValue)
                                .font(.caption)
                                .foregroundColor(AsaColors.mocha)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("新しい習慣")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        Task {
                            await viewModel.addHabit(
                                name: habitName,
                                description: habitDescription,
                                category: selectedCategory,
                                icon: selectedIcon,
                                color: selectedColor,
                                frequency: selectedFrequency,
                                reminderTime: reminderEnabled ? reminderTime : nil
                            )
                            dismiss()
                        }
                    }
                    .disabled(habitName.isEmpty)
                }
            }
        }
    }
}