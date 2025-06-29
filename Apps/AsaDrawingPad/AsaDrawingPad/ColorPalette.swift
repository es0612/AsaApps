//
//  ColorPalette.swift
//  AsaDrawingPad
//  
//  Created on 2025/06/29
//

import SwiftUI

extension Color {
    static let asaCoffeeBrown = Color(red: 0.78, green: 0.55, blue: 0.33)
    static let asaMocha = Color(red: 0.55, green: 0.35, blue: 0.17)
    static let asaSoftCream = Color(red: 0.91, green: 0.84, blue: 0.73)
    static let asaDarkSlate = Color(red: 0.18, green: 0.24, blue: 0.27)
    static let asaMutedSage = Color(red: 0.48, green: 0.57, blue: 0.55)
}

struct ColorPaletteView: View {
    @Bindable var drawingModel: DrawingModel
    
    let colors: [Color] = [
        .asaCoffeeBrown,
        .asaMocha,
        .asaDarkSlate,
        .asaMutedSage,
        .black,
        .red,
        .blue,
        .green,
        .orange,
        .purple
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(
                                drawingModel.selectedColor == color ? Color.gray : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .onTapGesture {
                        drawingModel.selectedColor = color
                    }
            }
        }
        .padding(.horizontal)
    }
}

struct BrushSizeSlider: View {
    @Bindable var drawingModel: DrawingModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("線の太さ")
                    .font(.caption)
                    .foregroundColor(.asaDarkSlate)
                Spacer()
                Text("\(Int(drawingModel.lineWidth))px")
                    .font(.caption)
                    .foregroundColor(.asaMocha)
            }
            
            Slider(value: $drawingModel.lineWidth, in: 1...10, step: 1)
                .accentColor(.asaCoffeeBrown)
        }
        .padding(.horizontal)
    }
}