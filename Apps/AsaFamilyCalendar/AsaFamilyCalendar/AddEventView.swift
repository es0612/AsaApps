import SwiftUI

struct AddEventView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isAllDay = false
    @State private var category = "その他"
    @State private var reminder: Int = 0
    @State private var selectedMember: FamilyMember?
    
    private let categories = ["仕事", "家事", "レジャー", "医療", "学校", "その他"]
    private let reminderOptions = [
        (0, "なし"),
        (5, "5分前"),
        (15, "15分前"),
        (30, "30分前"),
        (60, "1時間前"),
        (1440, "1日前")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("タイトル", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("説明（任意）", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("カテゴリ", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("日時")) {
                    Toggle("終日", isOn: $isAllDay)
                        .toggleStyle(SwitchToggleStyle(tint: Color("AsaCoffeeBrown")))
                    
                    if isAllDay {
                        DatePicker("日付", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    } else {
                        DatePicker("開始日時", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        DatePicker("終了日時", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
                
                Section(header: Text("担当者")) {
                    Picker("家族メンバー", selection: $selectedMember) {
                        Text("なし").tag(nil as FamilyMember?)
                        ForEach(viewModel.familyMembers, id: \.id) { member in
                            if member.isActive {
                                HStack {
                                    Circle()
                                        .fill(Color(member.color ?? "AsaCoffeeBrown"))
                                        .frame(width: 12, height: 12)
                                    Text(member.name ?? "")
                                }
                                .tag(member as FamilyMember?)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("リマインダー")) {
                    Picker("通知", selection: $reminder) {
                        ForEach(reminderOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationBarTitle("イベント追加", displayMode: .inline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveEvent()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            startDate = viewModel.selectedDate
            endDate = Calendar.current.date(byAdding: .hour, value: 1, to: viewModel.selectedDate) ?? Date()
            viewModel.fetchFamilyMembers()
        }
    }
    
    private func saveEvent() {
        let finalEndDate = isAllDay ? nil : endDate
        
        DispatchQueue.main.async {
            self.viewModel.addEvent(
                title: self.title,
                description: self.description,
                startDate: self.startDate,
                endDate: finalEndDate,
                isAllDay: self.isAllDay,
                category: self.category,
                reminder: Int16(self.reminder),
                member: self.selectedMember
            )
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditEventView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.presentationMode) var presentationMode
    
    let event: Event
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isAllDay = false
    @State private var category = "その他"
    @State private var reminder: Int = 0
    @State private var selectedMember: FamilyMember?
    
    private let categories = ["仕事", "家事", "レジャー", "医療", "学校", "その他"]
    private let reminderOptions = [
        (0, "なし"),
        (5, "5分前"),
        (15, "15分前"),
        (30, "30分前"),
        (60, "1時間前"),
        (1440, "1日前")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("タイトル", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("説明（任意）", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("カテゴリ", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("日時")) {
                    Toggle("終日", isOn: $isAllDay)
                        .toggleStyle(SwitchToggleStyle(tint: Color("AsaCoffeeBrown")))
                    
                    if isAllDay {
                        DatePicker("日付", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    } else {
                        DatePicker("開始日時", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        DatePicker("終了日時", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
                
                Section(header: Text("担当者")) {
                    Picker("家族メンバー", selection: $selectedMember) {
                        Text("なし").tag(nil as FamilyMember?)
                        ForEach(viewModel.familyMembers, id: \.id) { member in
                            if member.isActive {
                                HStack {
                                    Circle()
                                        .fill(Color(member.color ?? "AsaCoffeeBrown"))
                                        .frame(width: 12, height: 12)
                                    Text(member.name ?? "")
                                }
                                .tag(member as FamilyMember?)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("リマインダー")) {
                    Picker("通知", selection: $reminder) {
                        ForEach(reminderOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    Button("削除") {
                        deleteEvent()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationBarTitle("イベント編集", displayMode: .inline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveEvent()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            loadEventData()
            viewModel.fetchFamilyMembers()
        }
    }
    
    private func loadEventData() {
        title = event.title ?? ""
        description = event.eventDescription ?? ""
        startDate = event.startDate ?? Date()
        endDate = event.endDate ?? Date()
        isAllDay = event.isAllDay
        category = event.category ?? "その他"
        reminder = Int(event.reminder)
        selectedMember = viewModel.memberForEvent(event)
    }
    
    private func saveEvent() {
        let finalEndDate = isAllDay ? nil : endDate
        
        DispatchQueue.main.async {
            self.viewModel.updateEvent(
                self.event,
                title: self.title,
                description: self.description,
                startDate: self.startDate,
                endDate: finalEndDate,
                isAllDay: self.isAllDay,
                category: self.category,
                reminder: Int16(self.reminder),
                member: self.selectedMember
            )
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func deleteEvent() {
        DispatchQueue.main.async {
            self.viewModel.deleteEvent(self.event)
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview("イベント追加") {
    AddEventView(viewModel: CalendarViewModel.withManyEvents)
}