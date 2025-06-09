// AsaApps/Apps/AsaRandomQuote/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var quotes = ["今日も一歩前へ！", "失敗は成功の第一歩", "笑顔でいこう！"]
    @State private var currentQuote = "今日も一歩前へ！"
    
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
                        .shadow(radius: 1)
                    
                    Text("アサパパの名言集")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                    
                    Text(currentQuote)
                        .font(.body.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.asaSoftCream.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    
    
                    AsaButton(title: "Test Button", action: {
                        currentQuote = quotes.randomElement() ?? "今日も一歩前へ！"
                    }, color: Color("AsaCoffeeBrown"))
                    .padding(.horizontal)
                    
                    NavigationLink("お気に入りを見る", destination: Text("未実装"))
                        .font(.body.weight(.medium))
                        .foregroundColor(.asaMutedSage)
                        .padding(.bottom, 20)
                    
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
