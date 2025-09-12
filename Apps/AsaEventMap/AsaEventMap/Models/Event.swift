//
//  Event.swift
//  AsaEventMap
//  
//  Created on 2025/09/12
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Event {
    var id: UUID
    var title: String
    var eventDescription: String
    var date: Date
    var category: EventCategory
    var latitude: Double
    var longitude: Double
    var address: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        title: String = "",
        eventDescription: String = "",
        date: Date = Date(),
        category: EventCategory = .other,
        latitude: Double = 35.6762,
        longitude: Double = 139.6503,
        address: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.eventDescription = eventDescription
        self.date = date
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    var isUpcoming: Bool {
        date > Date()
    }
    
    var isPast: Bool {
        date < Date()
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var daysUntilEvent: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return components.day ?? 0
    }
}