//
//  BookRowView.swift
//  AsaBookList
//  
//  Created on 2025/06/27
//

import SwiftUI

struct BookRowView: View {
    let book: Book
    let onStatusChange: (ReadingStatus) -> Void
    let onTap: () -> Void
    
    var body: some View {
        AsaCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .lineLimit(2)
                    
                    Text("著者: \(book.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Image(systemName: book.status.systemImage)
                            .foregroundColor(statusColor(for: book.status))
                        
                        Text(book.status.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor(for: book.status))
                    }
                    
                    if !book.notes.isEmpty {
                        Text(book.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Menu {
                        ForEach(ReadingStatus.allCases, id: \.self) { status in
                            Button(action: {
                                onStatusChange(status)
                            }) {
                                Label(status.rawValue, systemImage: status.systemImage)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    if book.status == .completed, let dateCompleted = book.dateCompleted {
                        VStack(spacing: 2) {
                            Text("完読日")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(dateCompleted, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .onTapGesture {
            onTap()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .toRead:
            return .gray
        case .reading:
            return .blue
        case .completed:
            return .green
        }
    }
}

#Preview {
    VStack {
        BookRowView(
            book: Book(title: "Swift実践入門", author: "増田 亨", status: .reading),
            onStatusChange: { _ in },
            onTap: {}
        )
        
        BookRowView(
            book: Book(title: "Clean Code", author: "Robert C. Martin", status: .completed),
            onStatusChange: { _ in },
            onTap: {}
        )
    }
    .background(Color("AsaSoftCream"))
}