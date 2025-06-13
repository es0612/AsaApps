import SwiftUI

struct ExpenseHistoryView: View {
    @State private var viewModel = ExpenseViewModel()
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.asaSoftCream, .asaMocha], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                if viewModel.expenses.isEmpty {
                    AsaCard {
                        Text("支出履歴がありません")
                            .font(.body.weight(.medium))
                            .foregroundColor(.asaMocha)
                    }
                    .padding(.horizontal)
                } else {
                    List {
                        ForEach(viewModel.expenses) { expense in
                            AsaCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(expense.amount, format: .currency(code: "JPY"))")
                                            .font(.body.weight(.medium))
                                            .foregroundColor(.asaCoffeeBrown)
                                        Text(expense.category)
                                            .font(.caption)
                                            .foregroundColor(.asaMutedSage)
                                    }
                                    Spacer()
                                    Text("\(expense.date, format: .dateTime.day().month().year())")
                                        .font(.caption)
                                        .foregroundColor(.asaMutedSage)
                                }
                            }
                            .padding(.horizontal, 8)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            let expensesToDelete = indexSet.map { viewModel.expenses[$0] }
                            viewModel.deleteExpense(expensesToDelete)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(.asaSoftCream)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("支出履歴")
            .onAppear {
                viewModel.loadFromUserDefaults()
            }
        }
    }
}

struct ExpenseHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseHistoryView()
    }
}
