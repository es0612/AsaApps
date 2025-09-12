//
//  EventListView.swift
//  AsaEventMap
//  
//  Created on 2025/09/12
//

import SwiftUI

struct EventListView: View {
    @Bindable var viewModel: EventMapViewModel
    @State private var showingFilterSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick Stats
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        StatCard(
                            title: "今日",
                            count: viewModel.todayEvents.count,
                            color: Color("AsaCoffeeBrown")
                        )
                        StatCard(
                            title: "今後",
                            count: viewModel.upcomingEvents.count,
                            color: Color("AsaMocha")
                        )
                        StatCard(
                            title: "全て",
                            count: viewModel.events.count,
                            color: Color("AsaMutedSage")
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 10)
                
                // Event List
                if viewModel.filteredEvents.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("イベントがありません")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        AsaButton(title: "イベントを追加") {
                            viewModel.isShowingAddEvent = true
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedEvents, id: \.key) { section in
                            Section(header: Text(section.key)) {
                                ForEach(section.value) { event in
                                    EventRow(event: event) {
                                        viewModel.selectedEvent = event
                                        viewModel.isShowingEventDetail = true
                                    }
                                }
                                .onDelete { indexSet in
                                    deleteEvents(at: indexSet, in: section.value)
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .frame(maxHeight: .infinity)
            .navigationTitle("イベント一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isShowingAddEvent = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $viewModel.isShowingAddEvent) {
                AddEventView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShowingEventDetail) {
                if let event = viewModel.selectedEvent {
                    EventDetailView(event: event, viewModel: viewModel)
                }
            }
        }
    }
    
    // MARK: - Grouped Events
    private var groupedEvents: [(key: String, value: [Event])] {
        let grouped = Dictionary(grouping: viewModel.filteredEvents) { event in
            if event.isToday {
                return "今日"
            } else if event.isUpcoming {
                let days = event.daysUntilEvent
                if days == 1 {
                    return "明日"
                } else if days <= 7 {
                    return "今週"
                } else if days <= 30 {
                    return "今月"
                } else {
                    return "今後"
                }
            } else {
                return "過去"
            }
        }
        
        let order = ["今日", "明日", "今週", "今月", "今後", "過去"]
        return grouped
            .sorted { first, second in
                let firstIndex = order.firstIndex(of: first.key) ?? Int.max
                let secondIndex = order.firstIndex(of: second.key) ?? Int.max
                return firstIndex < secondIndex
            }
            .map { ($0.key, $0.value.sorted { $0.date < $1.date }) }
    }
    
    // MARK: - Delete Events
    private func deleteEvents(at offsets: IndexSet, in events: [Event]) {
        for index in offsets {
            viewModel.deleteEvent(events[index])
        }
    }
}

// MARK: - Event Row Component
struct EventRow: View {
    let event: Event
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(event.category.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: event.category.iconName)
                        .foregroundColor(event.category.color)
                        .font(.system(size: 20))
                }
                
                // Event Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(event.formattedDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(event.address.isEmpty ? "場所未設定" : event.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Days Until
                if event.isUpcoming {
                    VStack {
                        Text("\(event.daysUntilEvent)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(event.category.color)
                        Text("日後")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 80, height: 60)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    EventListView(viewModel: EventMapViewModel())
}