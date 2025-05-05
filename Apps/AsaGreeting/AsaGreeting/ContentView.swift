//
//  ContentView.swift
//  AsaGreeting
//
//  Created on 2025/05/03
//


import SwiftUI

struct ContentView: View {
    // Mark: - Properties
    @State private var name = ""
    private let greeting = "おはよう"
    
    // Mark: - Body
    var body: some View {
        VStack(spacing: 20) {
            TextField("名前を入力", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding()
                .submitLabel(.done)
                .accentColor(Color("AsaCoffeeBrown"))
                .background(Color("AsaSoftCream").opacity(0.2))
                .cornerRadius(8)
            
            Text(name.isEmpty ? "\(greeting)！" : "\(greeting)、\(name)さん！")
                .font(.system(.title, design: .rounded))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            AsaButton(
                title: "クリア",
                action: { name = "" },
                color: Color("AsaMutedSage"),
                isEnabled: !name.isEmpty // 名前が空なら無効
            )
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("AsaDarkSlate"))
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
