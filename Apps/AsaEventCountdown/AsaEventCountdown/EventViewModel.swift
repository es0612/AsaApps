// AsaApps/Apps/AsaEventCountdown/ViewModels/EventViewModel.swift
import Observation
import Foundation

@Observable
class EventViewModel {
    var events: [Event] = []
    var eventName: String = ""
    var eventDate: Date = Date()
    
    func addEvent() {
        guard !eventName.isEmpty else { return }
        let newEvent = Event(name: eventName, date: eventDate)
        events.append(newEvent)
        saveToUserDefaults()
        eventName = ""
    }
    
    func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: "events")
        }
    }
    
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "events"),
           let savedEvents = try? JSONDecoder().decode([Event].self, from: data) {
            events = savedEvents
        }
    }
    
    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
        saveToUserDefaults()
    }
    
    func daysUntilEvent(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return max(0, components.day ?? 0)
    }
}
