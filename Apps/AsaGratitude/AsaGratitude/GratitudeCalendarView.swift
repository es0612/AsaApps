//
//  GratitudeCalendarView.swift
//  AsaGratitude
//  
//  Created on 2025/07/02
//

import SwiftUI

struct GratitudeCalendarView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // 週間ビュー
            WeeklyCalendarView(viewModel: viewModel, selectedDate: $selectedDate)
            
            Divider()
            
            // 選択された日の感謝エントリー
            SelectedDateEntriesView(viewModel: viewModel, selectedDate: selectedDate)
        }
        .navigationTitle("感謝カレンダー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WeeklyCalendarView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    var weekDates: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 月と年の表示
            HStack {
                Button(action: {
                    selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                Spacer()
                
                Text(monthYearString(for: selectedDate))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Spacer()
                
                Button(action: {
                    selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .padding(.horizontal)
            
            // 曜日ヘッダー
            HStack {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // 週の日付
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    DayCell(
                        date: date,
                        entries: viewModel.entriesForDate(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        onTap: {
                            selectedDate = date
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    private func monthYearString(for date: Date) -> String {
        dateFormatter.dateFormat = "yyyy年M月"
        return dateFormatter.string(from: date)
    }
}

struct DayCell: View {
    let date: Date
    let entries: [GratitudeEntry]
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(
                        isSelected ? .white :
                        isToday ? Color("AsaCoffeeBrown") :
                        .primary
                    )
                
                // 感謝エントリーのインジケーター
                HStack(spacing: 2) {
                    ForEach(0..<min(entries.count, 3), id: \.self) { index in
                        Circle()
                            .fill(Color(entries[index].category.color))
                            .frame(width: 4, height: 4)
                    }
                    
                    if entries.count > 3 {
                        Text("+")
                            .font(.system(size: 6))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 8)
            }
            .frame(width: 40, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ? Color("AsaCoffeeBrown") :
                        isToday ? Color("AsaSoftCream").opacity(0.3) :
                        Color.clear
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isToday && !isSelected ? Color("AsaCoffeeBrown") : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectedDateEntriesView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    let selectedDate: Date
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    var selectedEntries: [GratitudeEntry] {
        viewModel.entriesForDate(selectedDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(dateFormatter.string(from: selectedDate))
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Spacer()
                
                Text("\(selectedEntries.count)件の感謝")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)
            
            if selectedEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("AsaMutedSage").opacity(0.5))
                    
                    Text("この日の感謝記録はありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
                        AsaButton(title: "今日の感謝を記録", action: {
                            viewModel.showAddEntry()
                        })
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(selectedEntries) { entry in
                            GratitudeDetailRowView(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddEntry) {
            AddGratitudeView(viewModel: viewModel)
        }
    }
}

#Preview {
    NavigationView {
        GratitudeCalendarView(viewModel: GratitudeViewModel())
    }
}