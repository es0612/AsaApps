//
//  AsaTimerApp.swift
//  AsaTimer
//  
//  Created on 2025/05/08
//


import SwiftUI

@main
struct AsaTimerApp: App {
    @State private var showSplash = true

      var body: some Scene {
          WindowGroup {
              if showSplash {
                  AsaLaunchScreen(appName: "AsaTimer")
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
