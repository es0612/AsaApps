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
        VStack {
            // ここにUI追加
            Text("Count: \(count)")
                .font(.title)
            
            Button(action: {
                count += 1
            }) {
                Text("+1")
                    .font(.title2)
                    .padding()
                    .background(Color("AsaBlue"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
                count -= 1
            }) {
                Text("-1")
                    .font(.title2)
                    .padding()
                    .background(Color("AsaRed"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
