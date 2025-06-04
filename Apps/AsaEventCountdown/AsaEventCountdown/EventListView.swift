import SwiftUI

struct EventListView: View {
    @State private var viewModel = EventViewModel()
    
    var body: some View {
        List {
            if viewModel.events.isEmpty {
                Text("イベントがありません！")
                    .font(.body.weight(.medium))
                    .foregroundColor(.asaMocha)
            } else {
                ForEach(viewModel.events) { event in
                    Text("\(event.name) - あと \(viewModel.daysUntilEvent(from: event.date)) 日")
                        .font(.body.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                }
            }
        }
        .navigationTitle("イベント一覧")
        .background(.asaSoftCream)
        .onAppear {
            viewModel.loadFromUserDefaults()
        }
    }
}

struct EventListView_Previews: PreviewProvider {
    static var previews: some View {
        EventListView()
    }
}
