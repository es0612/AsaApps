//
//  ContentView.swift
//  AsaCounter
//
//  Created on 2025/04/30
//


import SwiftUI

struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(count)")
                .font(.title)
                .foregroundColor(Color("AsaCoffeeBrown"))
            AsaButton(title: "+1", action: { count += 1 }, color: Color("AsaCoffeeBrown"))
            AsaButton(title: "-1", action: { count -= 1 }, color: Color("AsaMocha"))
        }
        .padding()
        .background(Color("AsaDarkSlate"))
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
