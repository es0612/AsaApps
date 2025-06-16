import SwiftUI

struct HabitHistoryView: View {
    @State private var viewModel = HabitViewModel()
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.asaSoftCream, .asaMocha], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                if viewModel.habits.isEmpty {
                    AsaCard {
                        Text("履歴がありません")
                            .font(.body.weight(.medium))
                            .foregroundColor(.asaMocha)
                    }
                    .padding(.horizontal)
                } else {
                    List {
                        ForEach(viewModel.habits) { habit in
                            AsaCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(habit.name)
                                            .font(.body.weight(.medium))
                                            .foregroundColor(.asaCoffeeBrown)
                                        Text(habit.isChecked ? "完了済み" : "未完了")
                                            .font(.caption)
                                            .foregroundColor(.asaMutedSage)
                                    }
                                    Spacer()
                                    Text(habit.date, format: .dateTime.day().month().year())
                                        .font(.caption)
                                        .foregroundColor(.asaMutedSage)
                                }
                            }
                            .padding(.horizontal, 8)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            let habitsToDelete = indexSet.map { viewModel.habits[$0] }
                            viewModel.deleteHabit(habitsToDelete)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(.asaSoftCream)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("習慣履歴")
            .onAppear {
                viewModel.loadFromUserDefaults()
            }
        }
    }
}

struct HabitHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HabitHistoryView()
    }
}
