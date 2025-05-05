//
//  ContentView.swift
//  AsaCounter
//
//  Created on 2025/04/30
//


import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @State private var count = 0
    
    // MARK: - Body
    var body: some View {
        // 現在のカウント表示
        VStack(spacing: 20) {
            Text("Count: \(count)")
                .font(.system(.title, design: .rounded)) // 丸みを帯びたフォントで温かみ
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            AsaButton(title: "+1", action: { count += 1 }, color: Color("AsaCoffeeBrown"))
            
            AsaButton(
                title: "-1",
                action: { if count>0 {count -= 1 } },
                color: Color("AsaMocha"),
                isEnabled: count > 0 // 0以下の場合は無効
            )
        }
        .padding()
        .background(Color("AsaDarkSlate"))
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
