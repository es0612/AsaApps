//
//  AsaCounterApp.swift
//  AsaCounter
//
//  Created on 2025/04/30
//


import SwiftUI

@main
struct AsaCounterApp: App {
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                AsaLaunchScreen(appName: "AsaCounter")
                    .onAppear {
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
