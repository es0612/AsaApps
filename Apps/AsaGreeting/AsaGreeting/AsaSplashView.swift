//
//  AsaSplashView.swift
//  AsaGreeting
//  
//  Created on 2025/05/03
//


import SwiftUI

struct AsaSplashView: View {
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            Color("AsaBlue")
                .ignoresSafeArea()
            VStack {
                Text("アサパパらぼ。")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
                Text("AsaGreeting")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.5)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    AsaSplashView()
}
