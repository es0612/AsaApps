//
//  AsaLaunchScreen.swift
//  AsaCounter
//  
//  Created on 2025/05/02
//


import SwiftUI

struct AsaLaunchScreen: View {
    var body: some View {
        ZStack {
            Color("AsaBlue") // パステルブルー（Assets.xcassetsで設定済み）
                .ignoresSafeArea()
            VStack {
                Text("アサパパらぼ。")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("AsaCounter")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    AsaLaunchScreen()
}
