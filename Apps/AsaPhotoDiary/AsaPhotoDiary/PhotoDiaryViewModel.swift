//
//  PhotoDiaryViewModel.swift
//  AsaPhotoDiary
//  
//  Created on 2025/07/05
//

import Foundation
import CoreData
import SwiftUI
import PhotosUI

class PhotoDiaryViewModel: ObservableObject {
    @Published var entries: [DiaryEntry] = []
    @Published var filteredEntries: [DiaryEntry] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: DiaryCategory? = nil
    @Published var selectedMood: DiaryMood? = nil
    @Published var isShowingAddEntry = false
    @Published var isShowingFilters = false
    @Published var selectedEntry: DiaryEntry?
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = viewContext
        loadEntries()
    }
    
    // MARK: - Data Loading
    func loadEntries() {
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DiaryEntry.date, ascending: false)]
        
        do {
            entries = try viewContext.fetch(request)
            applyFilters()
        } catch {
            print("Error loading entries: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    func createEntry(title: String, content: String, category: DiaryCategory, mood: DiaryMood, imageData: Data?, date: Date = Date()) {
        let newEntry = DiaryEntry(context: viewContext)
        newEntry.id = UUID()
        newEntry.title = title
        newEntry.content = content
        newEntry.category = category.rawValue
        newEntry.mood = mood.rawValue
        newEntry.imageData = imageData
        newEntry.date = date
        newEntry.createdAt = Date()
        newEntry.updatedAt = Date()
        
        saveContext()
        loadEntries()
    }
    
    func updateEntry(_ entry: DiaryEntry, title: String, content: String, category: DiaryCategory, mood: DiaryMood, imageData: Data?, date: Date) {
        entry.title = title
        entry.content = content
        entry.category = category.rawValue
        entry.mood = mood.rawValue
        entry.imageData = imageData
        entry.date = date
        entry.updatedAt = Date()
        
        saveContext()
        loadEntries()
    }
    
    func deleteEntry(_ entry: DiaryEntry) {
        viewContext.delete(entry)
        saveContext()
        loadEntries()
    }
    
    func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = filteredEntries[index]
            viewContext.delete(entry)
        }
        saveContext()
        loadEntries()
    }
    
    // MARK: - Filtering and Search
    func applyFilters() {
        filteredEntries = entries.filter { entry in
            let matchesSearch = searchText.isEmpty || 
                (entry.title?.lowercased().contains(searchText.lowercased()) ?? false) ||
                (entry.content?.lowercased().contains(searchText.lowercased()) ?? false)
            
            let matchesCategory = selectedCategory == nil || entry.categoryEnum == selectedCategory
            let matchesMood = selectedMood == nil || entry.moodEnum == selectedMood
            
            return matchesSearch && matchesCategory && matchesMood
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedMood = nil
        applyFilters()
    }
    
    // MARK: - Statistics
    func getStats() -> DiaryStats {
        return DiaryStats(entries: entries)
    }
    
    // MARK: - Utility Methods
    func entriesForDate(_ date: Date) -> [DiaryEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            guard let entryDate = entry.date else { return false }
            return calendar.isDate(entryDate, inSameDayAs: date)
        }
    }
    
    func entriesForWeek(_ date: Date) -> [DiaryEntry] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        
        return entries.filter { entry in
            guard let entryDate = entry.date else { return false }
            return weekInterval.contains(entryDate)
        }
    }
    
    func entriesForMonth(_ date: Date) -> [DiaryEntry] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        
        return entries.filter { entry in
            guard let entryDate = entry.date else { return false }
            return monthInterval.contains(entryDate)
        }
    }
    
    // MARK: - Private Methods
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}