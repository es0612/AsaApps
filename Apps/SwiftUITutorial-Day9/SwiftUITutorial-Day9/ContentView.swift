//
//  ContentView.swift
//  SwiftUITutorial-Day9
//
//  Created on 2025/05/09
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List(landmarks) { landmark in
                NavigationLink(destination: LandmarkDetail(landmark: landmark)) {
                    LandmarkRow(landmark: landmark)
                }
            }
            .navigationTitle("Landmarks") // リスト画面のタイトル
        }
    }
}

#Preview {
    ContentView()
}
