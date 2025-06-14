import SwiftUI

struct ContentView: View {
    @State private var viewModel = ExpenseViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.asaSoftCream, .asaMocha], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image("AsaPapaLabLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .padding(.top, 8)
                        .shadow(radius: 1)
                    
                    Text("アサパパの支出トラッカー")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                    
                    AsaCard {
                        VStack(spacing: 12) {
                            TextField("金額を入力", text: $viewModel.amount)
                                .keyboardType(.decimalPad)
                                .font(.body.weight(.medium))
                                .foregroundColor(.asaCoffeeBrown)
                                .padding(.horizontal)
                                .onChange(of: viewModel.amount) { _, _ in
                                    viewModel.validateAmount()
                                }
                            if let error = viewModel.amountError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.asaMocha)
                                    .padding(.horizontal)
                            }
                            
                            Picker("カテゴリ", selection: $viewModel.category) {
                                ForEach(viewModel.categories, id: \.self) { category in
                                    Text(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.body.weight(.medium))
                            .foregroundColor(.asaCoffeeBrown)
                            
                            DatePicker("日付", selection: $viewModel.date, displayedComponents: .date)
                                .font(.body.weight(.medium))
                                .foregroundColor(.asaCoffeeBrown)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    AsaButton(title: "支出を追加") {
                        viewModel.addExpense()
                    }
                    .padding(.horizontal)
                    
                    NavigationLink("履歴を見る", destination: ExpenseHistoryView())
                        .font(.body.weight(.medium))
                        .foregroundColor(.asaMutedSage)
                        .padding(.bottom, 16)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .onAppear {
                viewModel.loadFromUserDefaults()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
