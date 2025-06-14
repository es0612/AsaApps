import SwiftUI

struct ContentView: View {
    @State private var habitName: String = ""
    
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
                            TextField("習慣を入力", text: $habitName)
                                .font(.body.weight(.medium))
                                .foregroundColor(.asaCoffeeBrown)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    AsaButton(title: "習慣を追加") {
                        print("追加: \(habitName)")
                        habitName = ""
                    }
                    .padding(.horizontal)
                    
                    AsaCard {
                        List {
                            Text("仮の習慣1")
                            Text("仮の習慣2")
                        }
                        .scrollContentBackground(.hidden)
                        .background(.asaSoftCream)
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
