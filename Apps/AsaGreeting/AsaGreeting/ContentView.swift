//
//  ContentView.swift
//  AsaGreeting
//
//  Created on 2025/05/03
//


import SwiftUI

struct ContentView: View {
    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("名前を入力", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .submitLabel(.done)
            Text(name.isEmpty ? "おはよう！" : "おはよう、\(name)さん！")
                .font(.system(.title, design: .rounded))
                .foregroundColor(Color("AsaBlue"))
        }
        .padding()
        .background(Color("AsaBlue").opacity(0.1))
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
