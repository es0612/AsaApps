import SwiftUI
import AsaUIKit

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var showAddEvent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // カレンダーヘッダー
                    HStack {
                        Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                            .font(.title)
                            .fontWeight(.bold)

                        Spacer()

                        Button(action: { showAddEvent = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(AsaColors.coffeeBrown)
                        }
                    }
                    .padding(.horizontal)

                    // 簡易カレンダービュー
                    CalendarGridView(selectedDate: $selectedDate)
                        .padding(.horizontal)

                    // 選択日の予定リスト
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(selectedDate.formatted(date: .abbreviated, time: .omitted))の予定")
                            .font(.headline)
                            .padding(.horizontal)

                        // プレースホルダー
                        AsaCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(EventCategory.work.color)
                                        .frame(width: 12, height: 12)
                                    Text("家族会議")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("15:00")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text("月次の家族会議")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventView()
        }
    }
}

struct CalendarGridView: View {
    @Binding var selectedDate: Date
    let calendar = Calendar.current
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var monthDates: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: selectedDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        var dates: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                dates.append(date)
            }
        }

        while dates.count % 7 != 0 {
            dates.append(nil)
        }

        return dates
    }

    var body: some View {
        VStack(spacing: 8) {
            // 曜日ヘッダー
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(symbol == "日" ? .red : symbol == "土" ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日付グリッド
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(monthDates.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 35)
                    }
                }
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? AsaColors.coffeeBrown : isToday ? AsaColors.softCream : Color.clear)
                    .frame(width: 35, height: 35)

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
            }
        }
    }
}