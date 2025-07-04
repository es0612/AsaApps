//
//  ContentView.swift
//  AsaFamilyCalendar
//  
//  Created on 2025/07/04
//


import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: CalendarViewModel
    
    init() {
        let persistenceController = PersistenceController.shared
        _viewModel = StateObject(wrappedValue: CalendarViewModel(persistenceController: persistenceController))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // カレンダーヘッダー
                CalendarHeaderView(viewModel: viewModel)
                
                // 曜日表示
                WeekdayHeaderView()
                
                // カレンダーグリッド
                CalendarGridView(viewModel: viewModel)
                
                // 選択した日のイベント一覧
                DayEventsView(viewModel: viewModel)
                
                Spacer()
            }
            .background(Color("AsaDarkSlate").opacity(0.05))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("家族メンバー") {
                            viewModel.isShowingMemberManager = true
                        }
                        Button("今後の予定") {
                            viewModel.isShowingUpcomingEvents = true
                        }
                    } label: {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isShowingAddEvent = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddEvent) {
                AddEventView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShowingMemberManager) {
                FamilyMemberManagerView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShowingUpcomingEvents) {
                UpcomingEventsView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.fetchEvents()
        }
    }
}

struct CalendarHeaderView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.navigateToMonth(-1)
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
            
            Spacer()
            
            VStack {
                Text(viewModel.monthYearString())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Button("今日") {
                    viewModel.goToToday()
                }
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
            }
            
            Spacer()
            
            Button(action: {
                viewModel.navigateToMonth(1)
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

struct WeekdayHeaderView: View {
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AsaMutedSage"))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color("AsaMocha").opacity(0.1))
    }
}

struct CalendarGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        let days = viewModel.daysInMonth()
        let startingSpaces = viewModel.startingDayOfWeek()
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
            // 前月の空白
            ForEach(0..<startingSpaces, id: \.self) { _ in
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 40)
            }
            
            // 現在の月の日付
            ForEach(days, id: \.self) { date in
                CalendarDayView(date: date, viewModel: viewModel)
            }
        }
        .padding(.horizontal)
    }
}

struct CalendarDayView: View {
    let date: Date
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        
        let isToday = Calendar.current.isDateInToday(date)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
        let hasEvents = viewModel.hasEventOnDate(date)
        
        return
        
        Button(action: {
            viewModel.selectedDate = date
        }) {
            VStack(spacing: 2) {
                Text(dayFormatter.string(from: date))
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : (isToday ? Color("AsaCoffeeBrown") : Color("AsaDarkSlate")))
                
                if hasEvents {
                    Circle()
                        .fill(Color("AsaMutedSage"))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(isSelected ? Color("AsaCoffeeBrown") : (isToday ? Color("AsaSoftCream") : Color.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DayEventsView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "M月d日"
        
        let events = viewModel.eventsForDate(viewModel.selectedDate)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dayFormatter.string(from: viewModel.selectedDate))
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Spacer()
                
                Button {
                    viewModel.selectedDate = viewModel.selectedDate
                    viewModel.isShowingAddEvent = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .padding(.horizontal)
            
            if events.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundColor(Color("AsaMutedSage"))
                    Text("予定がありません")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                    Button("イベントを追加") {
                        viewModel.isShowingAddEvent = true
                    }
                    .font(.caption)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(events, id: \.id) { event in
                            EventRowView(event: event, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(minHeight: 120, maxHeight: 200)
        .background(Color("AsaSoftCream").opacity(0.2))
    }
}

struct EventRowView: View {
    let event: Event
    @ObservedObject var viewModel: CalendarViewModel
    @State private var isShowingEditEvent = false
    
    var body: some View {
        Button(action: {
            isShowingEditEvent = true
        }) {
            HStack {
                Rectangle()
                    .fill(Color(viewModel.memberForEvent(event)?.color ?? "AsaCoffeeBrown"))
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    HStack {
                        if let member = viewModel.memberForEvent(event) {
                            Text(member.name ?? "")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                        
                        Text(event.category ?? "")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Spacer()
                        
                        if !event.isAllDay {
                            Text(formatTime(event.startDate))
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isShowingEditEvent) {
            EditEventView(viewModel: viewModel, event: event)
        }
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview("デフォルト") {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("空のカレンダー") {
    let viewModel = CalendarViewModel.empty
    return VStack {
        NavigationView {
            VStack(spacing: 0) {
                CalendarHeaderView(viewModel: viewModel)
                WeekdayHeaderView()
                CalendarGridView(viewModel: viewModel)
                DayEventsView(viewModel: viewModel)
                Spacer()
            }
            .background(Color("AsaDarkSlate").opacity(0.05))
        }
    }
}

#Preview("イベント多数") {
    let viewModel = CalendarViewModel.withManyEvents
    return VStack {
        NavigationView {
            VStack(spacing: 0) {
                CalendarHeaderView(viewModel: viewModel)
                WeekdayHeaderView()
                CalendarGridView(viewModel: viewModel)
                DayEventsView(viewModel: viewModel)
                Spacer()
            }
            .background(Color("AsaDarkSlate").opacity(0.05))
        }
    }
}
