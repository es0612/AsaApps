//
//  EventViewModel.swift
//  AsaEventPlanner
//  
//  Created on 2025/08/03
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class EventViewModel {
    private var modelContext: ModelContext
    
    var events: [Event] = []
    var templates: [EventTemplate] = []
    
    // UI State
    var isShowingAddEvent = false
    var isShowingTemplateSelection = false
    var selectedEvent: Event?
    var searchText = ""
    var filterType: EventType?
    var filterStatus: EventStatus?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadEvents()
        loadTemplates()
        createDefaultTemplatesIfNeeded()
    }
    
    // MARK: - Data Loading
    
    func loadEvents() {
        do {
            let descriptor = FetchDescriptor<Event>(
                sortBy: [SortDescriptor(\.eventDate, order: .forward)]
            )
            events = try modelContext.fetch(descriptor)
        } catch {
            print("イベントの読み込みに失敗しました: \(error)")
        }
    }
    
    func loadTemplates() {
        do {
            let descriptor = FetchDescriptor<EventTemplate>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            templates = try modelContext.fetch(descriptor)
        } catch {
            print("テンプレートの読み込みに失敗しました: \(error)")
        }
    }
    
    private func createDefaultTemplatesIfNeeded() {
        if templates.isEmpty {
            let defaultTemplates = EventTemplate.createDefaultTemplates()
            for template in defaultTemplates {
                modelContext.insert(template)
            }
            saveContext()
            loadTemplates()
        }
    }
    
    // MARK: - Event Management
    
    func addEvent(_ event: Event) {
        modelContext.insert(event)
        saveContext()
        loadEvents()
    }
    
    func updateEvent(_ event: Event) {
        event.updatedAt = Date()
        saveContext()
        loadEvents()
    }
    
    func deleteEvent(_ event: Event) {
        modelContext.delete(event)
        saveContext()
        loadEvents()
    }
    
    func createEventFromTemplate(_ template: EventTemplate, title: String, date: Date) -> Event {
        let event = Event(
            title: title,
            eventDate: date,
            eventType: template.eventType,
            budget: template.suggestedBudget
        )
        
        // デフォルトタスクの追加
        for taskTitle in template.defaultTasks {
            let task = EventTask(title: taskTitle)
            event.tasks.append(task)
            modelContext.insert(task)
        }
        
        return event
    }
    
    // MARK: - Task Management
    
    func addTask(to event: Event, title: String, description: String = "", priority: TaskPriority = .medium, dueDate: Date? = nil) {
        let task = EventTask(
            title: title,
            taskDescription: description,
            priority: priority,
            dueDate: dueDate
        )
        event.tasks.append(task)
        modelContext.insert(task)
        saveContext()
        loadEvents()
    }
    
    func updateTask(_ task: EventTask) {
        task.updatedAt = Date()
        saveContext()
        loadEvents()
    }
    
    func deleteTask(_ task: EventTask) {
        modelContext.delete(task)
        saveContext()
        loadEvents()
    }
    
    func toggleTaskCompletion(_ task: EventTask) {
        task.toggleCompletion()
        saveContext()
        loadEvents()
    }
    
    // MARK: - Participant Management
    
    func addParticipant(to event: Event, name: String, email: String = "", phone: String = "", role: String = "ゲスト") {
        let participant = Participant(
            name: name,
            email: email,
            phone: phone,
            role: role
        )
        event.participants.append(participant)
        modelContext.insert(participant)
        saveContext()
        loadEvents()
    }
    
    func updateParticipant(_ participant: Participant) {
        participant.updatedAt = Date()
        saveContext()
        loadEvents()
    }
    
    func deleteParticipant(_ participant: Participant) {
        modelContext.delete(participant)
        saveContext()
        loadEvents()
    }
    
    func updateParticipantStatus(_ participant: Participant, status: ParticipantStatus) {
        participant.updateStatus(status)
        saveContext()
        loadEvents()
    }
    
    // MARK: - Shopping Management
    
    func addShoppingItem(to event: Event, name: String, category: ShoppingCategory = .other, quantity: Int = 1, estimatedPrice: Double = 0.0) {
        let item = ShoppingItem(
            name: name,
            category: category,
            quantity: quantity,
            estimatedPrice: estimatedPrice
        )
        event.shoppingItems.append(item)
        modelContext.insert(item)
        saveContext()
        loadEvents()
    }
    
    func updateShoppingItem(_ item: ShoppingItem) {
        item.updatedAt = Date()
        saveContext()
        loadEvents()
    }
    
    func deleteShoppingItem(_ item: ShoppingItem) {
        modelContext.delete(item)
        saveContext()
        loadEvents()
    }
    
    func toggleItemPurchased(_ item: ShoppingItem, actualPrice: Double? = nil) {
        if item.isPurchased {
            item.markAsUnpurchased()
        } else {
            item.markAsPurchased(actualPrice: actualPrice)
        }
        
        // 実際の支出を更新
        if let event = item.event {
            updateEventActualSpent(event)
        }
        
        saveContext()
        loadEvents()
    }
    
    private func updateEventActualSpent(_ event: Event) {
        let total = event.shoppingItems
            .filter { $0.isPurchased }
            .reduce(0) { $0 + $1.totalActualCost }
        event.actualSpent = total
    }
    
    // MARK: - Filtering and Searching
    
    var filteredEvents: [Event] {
        var filtered = events
        
        // 検索フィルター
        if !searchText.isEmpty {
            filtered = filtered.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.eventDescription.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // タイプフィルター
        if let filterType = filterType {
            filtered = filtered.filter { $0.eventType == filterType }
        }
        
        // ステータスフィルター
        if let filterStatus = filterStatus {
            filtered = filtered.filter { $0.status == filterStatus }
        }
        
        return filtered
    }
    
    var upcomingEvents: [Event] {
        events.filter { $0.isUpcoming }.prefix(5).map { $0 }
    }
    
    var overdueEvents: [Event] {
        events.filter { event in
            event.eventDate < Date() && event.status != .completed && event.status != .cancelled
        }
    }
    
    // MARK: - Statistics
    
    var totalEvents: Int {
        events.count
    }
    
    var completedEvents: Int {
        events.filter { $0.status == .completed }.count
    }
    
    var totalBudget: Double {
        events.reduce(0) { $0 + $1.budget }
    }
    
    var totalSpent: Double {
        events.reduce(0) { $0 + $1.actualSpent }
    }
    
    // MARK: - Private Methods
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("データの保存に失敗しました: \(error)")
        }
    }
}