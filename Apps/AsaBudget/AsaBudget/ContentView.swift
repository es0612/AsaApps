// AsaApps/Apps/AsaBudget/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var amount: String = ""
    @State private var category: String = "食費"
    @State private var date: Date = Date()
    let categories = ["食費", "娯楽", "交通費", "生活費"]
    
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
                            TextField("金額を入力", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.body.weight(.medium))
                                .foregroundColor(.asaCoffeeBrown)
                                .padding(.horizontal)
                            
                            Picker("カテゴリ", selection: $category) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.body.weight(.medium))
                            .foregroundColor(.asaCoffeeBrown)
                            
                            DatePicker("日付", selection: $date, displayedComponents: .date)
                                .font(.body.weight(.medium))
                                .foregroundColor(.asaCoffeeBrown)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    AsaButton(title: "支出を追加") {
                        print("Tapped: ¥\(amount), カテゴリ: \(category), 日付: \(date)")
                        amount = ""
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
