//
//  LandmarkDetail.swift
//  SwiftUITutorial-Day12
//
//  Created on 2025/05/10
//



import SwiftUI

struct LandmarkDetail: View {
    let landmark: Landmark
    @State private var scale: CGFloat = 1.0 // ズーム状態
    
    var body: some View {
        VStack {
            Image(systemName: landmark.isFavorite ? "star.fill" : "star")
                .foregroundColor(.yellow)
                .scaleEffect(scale)
                .onTapGesture {
                    withAnimation {
                        scale = scale == 1.0 ? 1.5 : 1.0 // タップでズーム
                    }
                    
                }
                .onLongPressGesture {
                    print("Long pressed on \(landmark.name)")
                }
            Text(landmark.name)
                .font(.largeTitle)
                .foregroundColor(.blue)
            Text(landmark.park)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(landmark.description)
                .padding()
            Spacer()
        }
        .padding()
        .navigationTitle(landmark.name)
    }
}

#Preview {
    LandmarkDetail(landmark: landmarks[0])
}
