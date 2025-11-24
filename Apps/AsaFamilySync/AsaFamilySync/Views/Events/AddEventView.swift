import SwiftUI
import AsaUIKit

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var familyViewModel: FamilyGroupViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var selectedCategory = EventCategory.other
    @State private var isAllDay = false
    @State private var selectedMembers: Set<String> = []
    @State private var recurring = RecurringType.none
    @State private var reminders: Set<ReminderTime> = []
    @State private var location = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("タイトル", text: $title)

                    TextField("説明（任意）", text: $description, axis: .vertical)
                        .lineLimit(3...5)

                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                Section("日時") {
                    Toggle("終日", isOn: $isAllDay)

                    if isAllDay {
                        DatePicker("日付", selection: $startDate, displayedComponents: .date)
                    } else {
                        DatePicker("開始", selection: $startDate)
                        DatePicker("終了", selection: $endDate)
                    }

                    Picker("繰り返し", selection: $recurring) {
                        ForEach(RecurringType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("詳細設定") {
                    TextField("場所（任意）", text: $location)

                    NavigationLink {
                        SelectMembersView(
                            members: familyViewModel.familyMembers,
                            selectedMembers: $selectedMembers
                        )
                    } label: {
                        HStack {
                            Text("参加者")
                            Spacer()
                            if selectedMembers.isEmpty {
                                Text("全員")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(selectedMembers.count)名選択")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    NavigationLink {
                        SelectRemindersView(reminders: $reminders)
                    } label: {
                        HStack {
                            Text("リマインダー")
                            Spacer()
                            if reminders.isEmpty {
                                Text("なし")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(reminders.count)件")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("新しい予定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            guard let user = authViewModel.currentUser else { return }

                            let event = FamilyEvent(
                                title: title,
                                description: description.isEmpty ? nil : description,
                                startTime: startDate,
                                endTime: endDate,
                                category: selectedCategory,
                                createdBy: user.uid,
                                createdByName: user.displayName,
                                assignedTo: Array(selectedMembers)
                            )

                            var newEvent = event
                            newEvent.location = location.isEmpty ? nil : location
                            newEvent.isAllDay = isAllDay
                            newEvent.recurring = recurring
                            newEvent.reminders = Array(reminders)

                            await familyViewModel.createEvent(newEvent)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct SelectMembersView: View {
    let members: [FamilyMember]
    @Binding var selectedMembers: Set<String>

    var body: some View {
        List {
            if members.isEmpty {
                Text("メンバーがいません")
                    .foregroundColor(.secondary)
            } else {
                ForEach(members) { member in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.name)
                                .font(.body)
                            Text(member.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedMembers.contains(member.userId) {
                            Image(systemName: "checkmark")
                                .foregroundColor(AsaColors.coffeeBrown)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedMembers.contains(member.userId) {
                            selectedMembers.remove(member.userId)
                        } else {
                            selectedMembers.insert(member.userId)
                        }
                    }
                }
            }
        }
        .navigationTitle("参加者を選択")
    }
}

struct SelectRemindersView: View {
    @Binding var reminders: Set<ReminderTime>

    var body: some View {
        List {
            ForEach(ReminderTime.allCases, id: \.self) { reminder in
                HStack {
                    Text(reminder.displayName)
                    Spacer()
                    if reminders.contains(reminder) {
                        Image(systemName: "checkmark")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if reminders.contains(reminder) {
                        reminders.remove(reminder)
                    } else {
                        reminders.insert(reminder)
                    }
                }
            }
        }
        .navigationTitle("リマインダー")
    }
}