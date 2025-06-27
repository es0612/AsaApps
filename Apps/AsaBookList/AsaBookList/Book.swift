//
//  Book.swift
//  AsaBookList
//  
//  Created on 2025/06/27
//

import Foundation

enum ReadingStatus: String, CaseIterable, Codable {
    case toRead = "未読"
    case reading = "読書中"
    case completed = "完読"
    
    var systemImage: String {
        switch self {
        case .toRead:
            return "book.closed"
        case .reading:
            return "book"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
}

@Observable
class Book: Identifiable, Codable {
    let id = UUID()
    var title: String
    var author: String
    var status: ReadingStatus
    var dateAdded: Date
    var dateCompleted: Date?
    var notes: String
    
    init(title: String, author: String, status: ReadingStatus = .toRead, notes: String = "") {
        self.title = title
        self.author = author
        self.status = status
        self.dateAdded = Date()
        self.notes = notes
        
        if status == .completed {
            self.dateCompleted = Date()
        }
    }
    
    func markAsCompleted() {
        status = .completed
        dateCompleted = Date()
    }
    
    func updateStatus(_ newStatus: ReadingStatus) {
        status = newStatus
        if newStatus == .completed && dateCompleted == nil {
            dateCompleted = Date()
        } else if newStatus != .completed {
            dateCompleted = nil
        }
    }
}