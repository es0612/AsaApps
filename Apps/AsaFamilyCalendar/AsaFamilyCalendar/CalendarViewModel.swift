import Foundation
import CoreData
import SwiftUI

// MARK: - Mock Data Models
struct MockEvent {
    let id: UUID
    let title: String
    let eventDescription: String?
    let startDate: Date
    let endDate: Date?
    let isAllDay: Bool
    let category: String
    let reminder: Int16
    let createdDate: Date
    let memberID: UUID?
}

struct MockFamilyMember {
    let id: UUID
    let name: String
    let color: String
    let isActive: Bool
}

class CalendarViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var events: [Event] = []
    @Published var familyMembers: [FamilyMember] = []
    @Published var selectedDate: Date = Date()
    @Published var selectedMember: FamilyMember?
    @Published var isShowingAddEvent = false
    @Published var isShowingMemberManager = false
    @Published var isShowingUpcomingEvents = false
    
    // プレビュー用のプロパティ
    @Published var mockEvents: [MockEvent] = []
    @Published var mockFamilyMembers: [MockFamilyMember] = []
    @Published var isPreviewMode = false
    
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadData()
    }
    
    private func loadData() {
        fetchFamilyMembers()
        fetchEvents()
    }
    
    func fetchFamilyMembers() {
        let request: NSFetchRequest<FamilyMember> = FamilyMember.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            familyMembers = try persistenceController.container.viewContext.fetch(request)
        } catch {
            print("家族メンバー取得エラー: \(error)")
        }
    }
    
    func fetchEvents() {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        
        do {
            events = try persistenceController.container.viewContext.fetch(request)
        } catch {
            print("イベント取得エラー: \(error)")
        }
    }
    
    func eventsForDate(_ date: Date) -> [Event] {
        if isPreviewMode {
            let calendar = Calendar.current
            return mockEvents.compactMap { mockEvent in
                if calendar.isDate(mockEvent.startDate, inSameDayAs: date) {
                    return mockEventToEvent(mockEvent)
                }
                return nil
            }
        } else {
            let calendar = Calendar.current
            return events.filter { event in
                calendar.isDate(event.startDate ?? Date(), inSameDayAs: date)
            }
        }
    }
    
    func eventsForMember(_ member: FamilyMember) -> [Event] {
        return events.filter { event in
            event.memberID == member.id
        }
    }
    
    func memberForEvent(_ event: Event) -> FamilyMember? {
        guard let memberID = event.memberID else { return nil }
        
        if isPreviewMode {
            if let mockMember = mockFamilyMembers.first(where: { $0.id == memberID }) {
                return mockMemberToFamilyMember(mockMember)
            }
        }
        
        return familyMembers.first { $0.id == memberID }
    }
    
    func hasEventOnDate(_ date: Date) -> Bool {
        return !eventsForDate(date).isEmpty
    }
    
    func addEvent(title: String, description: String, startDate: Date, endDate: Date?, isAllDay: Bool, category: String, reminder: Int16?, member: FamilyMember?) {
        let newEvent = Event(context: persistenceController.container.viewContext)
        newEvent.id = UUID()
        newEvent.title = title
        newEvent.eventDescription = description
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        newEvent.isAllDay = isAllDay
        newEvent.category = category
        newEvent.reminder = reminder ?? 0
        newEvent.createdDate = Date()
        newEvent.memberID = member?.id
        
        saveContext()
        objectWillChange.send()
        fetchEvents()
    }
    
    func updateEvent(_ event: Event, title: String, description: String, startDate: Date, endDate: Date?, isAllDay: Bool, category: String, reminder: Int16?, member: FamilyMember?) {
        event.title = title
        event.eventDescription = description
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.category = category
        event.reminder = reminder ?? 0
        event.memberID = member?.id
        
        saveContext()
        objectWillChange.send()
        fetchEvents()
    }
    
    func deleteEvent(_ event: Event) {
        persistenceController.container.viewContext.delete(event)
        saveContext()
        objectWillChange.send()
        fetchEvents()
    }
    
    func addFamilyMember(name: String, color: String) {
        let newMember = FamilyMember(context: persistenceController.container.viewContext)
        newMember.id = UUID()
        newMember.name = name
        newMember.color = color
        newMember.isActive = true
        
        saveContext()
        objectWillChange.send()
        fetchFamilyMembers()
    }
    
    func updateFamilyMember(_ member: FamilyMember, name: String, color: String, isActive: Bool) {
        member.name = name
        member.color = color
        member.isActive = isActive
        
        saveContext()
        objectWillChange.send()
        fetchFamilyMembers()
    }
    
    func deleteFamilyMember(_ member: FamilyMember) {
        persistenceController.container.viewContext.delete(member)
        saveContext()
        objectWillChange.send()
        fetchFamilyMembers()
    }
    
    func navigateToMonth(_ direction: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: direction, to: currentDate) {
            currentDate = newDate
        }
    }
    
    func goToToday() {
        currentDate = Date()
        selectedDate = Date()
    }
    
    private func saveContext() {
        do {
            try persistenceController.container.viewContext.save()
        } catch {
            print("保存エラー: \(error)")
        }
    }
    
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentDate)
    }
    
    func daysInMonth() -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
        let range = calendar.range(of: .day, in: .month, for: currentDate) ?? 1..<32
        
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    func firstDayOfMonth() -> Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
    }
    
    func startingDayOfWeek() -> Int {
        let calendar = Calendar.current
        let firstDay = firstDayOfMonth()
        return calendar.component(.weekday, from: firstDay) - 1
    }
}

// MARK: - Preview Extensions
extension CalendarViewModel {
    // モックデータ変換メソッド
    func mockEventToEvent(_ mockEvent: MockEvent) -> Event {
        let event = Event(context: persistenceController.container.viewContext)
        event.id = mockEvent.id
        event.title = mockEvent.title
        event.eventDescription = mockEvent.eventDescription
        event.startDate = mockEvent.startDate
        event.endDate = mockEvent.endDate
        event.isAllDay = mockEvent.isAllDay
        event.category = mockEvent.category
        event.reminder = mockEvent.reminder
        event.createdDate = mockEvent.createdDate
        event.memberID = mockEvent.memberID
        return event
    }
    
    func mockMemberToFamilyMember(_ mockMember: MockFamilyMember) -> FamilyMember {
        let member = FamilyMember(context: persistenceController.container.viewContext)
        member.id = mockMember.id
        member.name = mockMember.name
        member.color = mockMember.color
        member.isActive = mockMember.isActive
        return member
    }
    
    static var preview: CalendarViewModel {
        let viewModel = CalendarViewModel(persistenceController: PersistenceController.preview)
        return viewModel
    }
    
    static var empty: CalendarViewModel {
        let viewModel = CalendarViewModel(persistenceController: PersistenceController.preview)
        viewModel.events = []
        viewModel.familyMembers = []
        viewModel.isPreviewMode = true
        return viewModel
    }
    
    static var withManyEvents: CalendarViewModel {
        let viewModel = CalendarViewModel(persistenceController: PersistenceController.preview)
        
        // プレビュー用のサンプルデータを直接作成
        let calendar = Calendar.current
        let now = Date()
        
        // サンプル家族メンバー
        let mockPapa = MockFamilyMember(id: UUID(), name: "パパ", color: "AsaCoffeeBrown", isActive: true)
        let mockMama = MockFamilyMember(id: UUID(), name: "ママ", color: "AsaSoftCream", isActive: true)
        let mockChild = MockFamilyMember(id: UUID(), name: "こども", color: "AsaMutedSage", isActive: true)
        
        viewModel.mockFamilyMembers = [mockPapa, mockMama, mockChild]
        
        // サンプルイベント
        var mockEvents: [MockEvent] = []
        
        // 今日のイベント
        mockEvents.append(MockEvent(
            id: UUID(),
            title: "家族でお出かけ",
            eventDescription: "近所の公園でピクニック",
            startDate: now,
            endDate: calendar.date(byAdding: .hour, value: 3, to: now),
            isAllDay: false,
            category: "レジャー",
            reminder: 30,
            createdDate: now,
            memberID: mockPapa.id
        ))
        
        // 明日のイベント
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        mockEvents.append(MockEvent(
            id: UUID(),
            title: "買い物",
            eventDescription: "食材の買い出し",
            startDate: tomorrow,
            endDate: nil,
            isAllDay: true,
            category: "家事",
            reminder: 0,
            createdDate: now,
            memberID: mockMama.id
        ))
        
        // 来週のイベント
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now)!
        mockEvents.append(MockEvent(
            id: UUID(),
            title: "歯医者の予約",
            eventDescription: "",
            startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: nextWeek)!,
            endDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: nextWeek)!,
            isAllDay: false,
            category: "医療",
            reminder: 60,
            createdDate: now,
            memberID: mockChild.id
        ))
        
        // 今月のその他のイベント
        for i in 2..<15 {
            let eventDate = calendar.date(byAdding: .day, value: i, to: now)!
            mockEvents.append(MockEvent(
                id: UUID(),
                title: "予定\(i)",
                eventDescription: "サンプルの予定です",
                startDate: eventDate,
                endDate: nil,
                isAllDay: Bool.random(),
                category: ["仕事", "家事", "レジャー", "学校"].randomElement()!,
                reminder: [0, 15, 30, 60].randomElement()!,
                createdDate: now,
                memberID: [mockPapa.id, mockMama.id, mockChild.id].randomElement()!
            ))
        }
        
        viewModel.mockEvents = mockEvents
        viewModel.isPreviewMode = true
        
        return viewModel
    }
}