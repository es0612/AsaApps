//
//  AsaGreetingApp.swift
//  AsaGreeting
//  
//  Created on 2025/05/03
//


import SwiftUI

@main
struct AsaGreetingApp: App {
    @State private var showSplash = true

        var body: some Scene {
            WindowGroup {
                if showSplash {
                    AsaSplashView()
                        .onAppear {
                            // 2秒後にスプラッシュを非表示
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    ContentView()
                }
            }
        }
}
