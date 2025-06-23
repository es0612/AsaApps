//
//  AsaSplashView.swift
//  AsaGreeting
//  
//  Created on 2025/05/03
//


import SwiftUI

struct AsaLaunchScreen: View {
    //Mark: - Properties
    let appName: String
    @State private var opacity = 0.0

    //Mark: - Body
    var body: some View {
            ZStack {
                
                Color("AsaDarkSlate")
                    .ignoresSafeArea()
                
                VStack {
                    Image("AsaLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    Text("　アサパパらぼ。")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaSoftCream"))
                    Text(appName)
                        .font(.title2)
                        .foregroundColor(Color("AsaSoftCream").opacity(0.8))
                }
            }
        }
}

#Preview {
    AsaLaunchScreen(appName: "test app")
}
