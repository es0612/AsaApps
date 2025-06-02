import SwiftUI

struct MoodHistoryView: View {
    let entries: [MoodEntry]
    
    var body: some View {
        List {
            ForEach(entries) { entry in
                Text("\(entry.date, formatter: dateFormatter) - \(entry.emoji)")
                    .font(.body)
                    .foregroundColor(.asaCoffeeBrown)
            }
        }
        .navigationTitle("気分履歴")
        .background(.asaSoftCream)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter
}()

struct MoodHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        MoodHistoryView(entries: [MoodEntry(date: Date(), emoji: "😊")])
    }
}
