
import SwiftUI

struct IntakeHistoryView: View {
    let history: [WaterLog]

    var body: some View {
        List {
            ForEach(history.sorted(by: { $0.date > $1.date })) { log in
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("\(log.date, formatter: itemFormatter)")
                    Spacer()
                    Text("\(log.amount, specifier: "%.0f") ml")
                        .fontWeight(.bold)
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("水分摂取の履歴")
        .listStyle(InsetGroupedListStyle())
    }

    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}
