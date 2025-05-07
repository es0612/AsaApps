//
//  ContentView.swift
//  SwiftUITutorial-Day6
//
//  Created on 2025/05/07
//


import SwiftUI

struct ContentView: View {
    @State private var tapCount = 0
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image("AsaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                HStack {
                    Text("Hello")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("SwiftUI!")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                }
                
                Button(action: {
                    tapCount += 1
                }) {
                    Text("Tap me!")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }}
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
