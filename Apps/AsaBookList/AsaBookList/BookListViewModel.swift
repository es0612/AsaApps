//
//  BookListViewModel.swift
//  AsaBookList
//  
//  Created on 2025/06/27
//

import Foundation

@Observable
class BookListViewModel {
    private let userDefaultsKey = "SavedBooks"
    
    var books: [Book] = []
    var selectedFilter: ReadingStatus? = nil
    
    var filteredBooks: [Book] {
        if let filter = selectedFilter {
            return books.filter { $0.status == filter }
        }
        return books
    }
    
    var readingStatistics: (toRead: Int, reading: Int, completed: Int) {
        let toRead = books.filter { $0.status == .toRead }.count
        let reading = books.filter { $0.status == .reading }.count
        let completed = books.filter { $0.status == .completed }.count
        return (toRead, reading, completed)
    }
    
    init() {
        loadBooks()
    }
    
    func addBook(_ book: Book) {
        books.append(book)
        saveBooks()
    }
    
    func deleteBook(_ book: Book) {
        books.removeAll { $0.id == book.id }
        saveBooks()
    }
    
    func updateBook(_ book: Book) {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
            saveBooks()
        }
    }
    
    func updateBookStatus(_ book: Book, status: ReadingStatus) {
        book.updateStatus(status)
        saveBooks()
    }
    
    private func saveBooks() {
        if let encoded = try? JSONEncoder().encode(books) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadBooks() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedBooks = try? JSONDecoder().decode([Book].self, from: data) {
            books = decodedBooks
        } else {
            // 初期データを追加
            addSampleBooks()
        }
    }
    
    private func addSampleBooks() {
        let sampleBooks = [
            Book(title: "Swift実践入門", author: "増田 亨", status: .reading),
            Book(title: "Clean Code", author: "Robert C. Martin", status: .toRead),
            Book(title: "SwiftUIの基礎", author: "朝活パパ", status: .completed)
        ]
        
        for book in sampleBooks {
            addBook(book)
        }
    }
}