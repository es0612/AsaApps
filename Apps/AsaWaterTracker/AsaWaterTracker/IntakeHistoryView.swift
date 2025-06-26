
import SwiftUI

struct IntakeHistoryView: View {
    let history: [WaterLog]
    
    var body: some View {
        List(history.sorted(by: { $0.date > $1.date })) { log in
            HStack {
                Text("\(log.date, formatter: itemFormatter)")
                Spacer()
                Text("\(log.amount, specifier: "%.0f") ml")
            }
        }
        .navigationTitle("摂取履歴")
    }
    
    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }
}
