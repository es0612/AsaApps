import SwiftUI

// MARK: - TimelineDateHeader

/// タイムラインの日付ヘッダー
struct TimelineDateHeader: View {
    let date: Date

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(isToday ? "今日" : date.formatted(.dateTime.month().day().weekday(.wide)))
                    .font(.title2.weight(.bold))

                if !isToday {
                    Text(date.formatted(.dateTime.year()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }
}
