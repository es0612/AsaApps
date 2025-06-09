import SwiftUI

struct ContentView: View {
    @State private var viewModel = UnitConverterViewModel()
    
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
                        .padding(.top, 20)
                    
                    Text("アサパパの単位変換")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                    
                    TextField("数値を入力（例：100）", text: $viewModel.inputValue)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(.asaMutedSage, lineWidth: 1)
                        )
                        .shadow(radius: 1)
                        .keyboardType(.decimalPad)

                    if viewModel.inputValue.isEmpty || Double(viewModel.inputValue) == nil {
                        Text("有効な数値を入力してください")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                    
                    Picker("単位", selection: $viewModel.unitType) {
                        ForEach(viewModel.unitTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.asaMutedSage)
                    .padding(.horizontal)
                    
                    Text("結果：\(viewModel.convertedValue, specifier: "%.3f") \(viewModel.unitType == "m→ft" ? "ft" : "lb")")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                        .padding()
                        .background(.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(radius: 2)
                    
                    Button("変換") {
                        viewModel.convert()
                    }
                    .font(.title2.weight(.bold))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.asaCoffeeBrown)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 3)
                    .padding(.horizontal)
                    
                    NavigationLink("履歴を見る", destination: ConversionListView())
                        .font(.body.weight(.medium))
                        .foregroundColor(.asaMutedSage)
                        .padding(.bottom, 20)
                    
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
