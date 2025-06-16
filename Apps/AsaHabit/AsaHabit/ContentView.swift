import SwiftUI

struct ContentView: View {
    @State private var viewModel = HabitViewModel()
    
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
                    
                    Text("アサパパの習慣チェッカー")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                    
                    AsaCard {
                        VStack(spacing: 12) {
                            TextField("習慣を入力", text: $viewModel.habitName)
                                .font(.body.weight(.medium))
                                .foregroundColor(.asaCoffeeBrown)
                                .padding(.horizontal)
                                .onChange(of: viewModel.habitName) { _, _ in
                                    viewModel.validateHabitName()
                                }
                            if let error = viewModel.nameError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.asaMocha)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    AsaButton(title: "習慣を追加") {
                        viewModel.addHabit()
                    }
                    .padding(.horizontal)
                    
                    AsaCard {
                        if viewModel.habits.isEmpty {
                            Text("習慣がありません")
                                .font(.body.weight(.medium))
                                .foregroundColor(.asaMocha)
                                .padding()
                        } else {
                            List {
                                ForEach(viewModel.habits) { habit in
                                    HStack {
                                        Text(habit.name)
                                            .font(.body.weight(.medium))
                                            .foregroundColor(.asaCoffeeBrown)
                                        Spacer()
                                        Image(systemName: habit.isChecked ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(.asaMutedSage)
                                            .onTapGesture {
                                                viewModel.toggleCheck(for: habit)
                                            }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .background(.asaSoftCream)
                        }
                    }
                    .padding(.horizontal)
                    
                    NavigationLink("履歴を見る", destination: Text("未実装"))
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
