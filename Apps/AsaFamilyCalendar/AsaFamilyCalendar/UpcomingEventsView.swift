import SwiftUI

struct UpcomingEventsView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                let upcomingEvents = getUpcomingEvents()
                
                if upcomingEvents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.title)
                            .foregroundColor(Color("AsaMutedSage"))
                        Text("今後の予定がありません")
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(upcomingEvents, id: \.id) { event in
                        UpcomingEventRow(event: event, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("今後の予定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func getUpcomingEvents() -> [Event] {
        let now = Date()
        return viewModel.events
            .filter { event in
                guard let startDate = event.startDate else { return false }
                return startDate >= now
            }
            .sorted { event1, event2 in
                guard let date1 = event1.startDate, let date2 = event2.startDate else { return false }
                return date1 < date2
            }
            .prefix(20)
            .map { $0 }
    }
}

struct UpcomingEventRow: View {
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
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    HStack {
                        Text(formatDate(event.startDate))
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        if let member = viewModel.memberForEvent(event) {
                            Text("• \(member.name ?? "")")
                                .font(.subheadline)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                        
                        Spacer()
                        
                        Text(event.category ?? "")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color("AsaSoftCream"))
                            .cornerRadius(4)
                            .foregroundColor(Color("AsaDarkSlate"))
                    }
                    
                    if let description = event.eventDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack {
                    if !event.isAllDay {
                        Text(formatTime(event.startDate))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    } else {
                        Text("終日")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    if event.reminder > 0 {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isShowingEditEvent) {
            EditEventView(viewModel: viewModel, event: event)
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview("空の予定") {
    UpcomingEventsView(viewModel: CalendarViewModel.empty)
}

#Preview("予定あり") {
    UpcomingEventsView(viewModel: CalendarViewModel.withManyEvents)
}