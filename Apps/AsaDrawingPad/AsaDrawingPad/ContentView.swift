//
//  ContentView.swift
//  AsaDrawingPad
//  
//  Created on 2025/06/29
//

import SwiftUI

struct ContentView: View {
    @State private var drawingModel = DrawingModel()
    
    var body: some View {
        VStack(spacing: 0) {
            titleSection
            canvasSection
            toolPanel
        }
        .background(Color.asaSoftCream.opacity(0.3))
    }
    
    private var titleSection: some View {
        Text("AsaDrawingPad")
            .font(.title.weight(.bold))
            .foregroundColor(.asaCoffeeBrown)
            .padding(.top)
    }
    
    private var canvasSection: some View {
        CanvasView(drawingModel: drawingModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
    
    private var toolPanel: some View {
        VStack(spacing: 16) {
            ColorPaletteView(drawingModel: drawingModel)
            BrushSizeSlider(drawingModel: drawingModel)
            buttonRow
        }
        .padding(.bottom)
        .background(Color.asaSoftCream.opacity(0.5))
    }
    
    private var buttonRow: some View {
        HStack(spacing: 12) {
            undoButton
            Spacer()
            clearButton
        }
        .padding(.horizontal)
    }
    
    private var undoButton: some View {
        Button(action: {
            drawingModel.undoLastLine()
        }) {
            Text("元に戻す")
                .font(.title3.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.asaMutedSage)
                .cornerRadius(10)
                .shadow(radius: 2)
        }
        .disabled(drawingModel.lines.isEmpty)
    }
    
    private var clearButton: some View {
        Button(action: {
            drawingModel.clearCanvas()
        }) {
            Text("全消去")
                .font(.title3.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.asaMocha)
                .cornerRadius(10)
                .shadow(radius: 2)
        }
        .disabled(drawingModel.lines.isEmpty)
    }
}

#Preview {
    ContentView()
}
