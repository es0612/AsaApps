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
            Text(name.isEmpty ? "こんにちは！" : "こんにちは、\(name)さん！")
                .font(.title)
                .foregroundColor(Color("AsaBlue"))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
