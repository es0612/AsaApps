// AsaApps/Apps/AsaUnitConverter/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var inputValue: String = ""
    @State private var unitType: String = "m→ft"
    @State private var convertedValue: Double = 0.0
    
    let unitTypes = ["m→ft", "kg→lb"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image("AsaPapaLabLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                Text("アサパパの単位変換")
                    .font(.title2.weight(.medium))
                    .foregroundColor(.asaCoffeeBrown)
                
                TextField("数値を入力（例：100）", text: $inputValue)
                    .padding()
                    .border(.asaMutedSage, width: 1)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .keyboardType(.decimalPad)
                
                Picker("単位", selection: $unitType) {
                    ForEach(unitTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(.menu)
                .tint(.asaMutedSage)
                .padding()
                
                Text("結果：\(convertedValue, specifier: "%.3f") \(unitType == "m→ft" ? "ft" : "lb")")
                    .font(.title3.weight(.medium))
                    .foregroundColor(.asaCoffeeBrown)
                
                Button("変換") {
                    if let value = Double(inputValue) {
                        convertedValue = unitType == "m→ft" ? value * 3.28084 : value * 2.20462
                    }
                }
                .font(.title2.weight(.medium))
                .padding()
                .background(.asaCoffeeBrown)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 2)
                
                NavigationLink("履歴を見る", destination: Text("未実装"))
                    .font(.title2.weight(.medium))
                    .foregroundColor(.asaMutedSage)
            }
            .padding()
            .background(.asaSoftCream)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
