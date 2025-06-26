//
//  ContentView.swift
//  AsaWaterTracker
//  
//  Created on 2025/06/26
//


import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WaterIntakeViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.3)
                        .foregroundColor(Color.blue)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(viewModel.progress, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.blue)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: viewModel.progress)
                    
                    VStack {
                        Text(String(format: "%.0f %%", min(viewModel.progress, 1.0) * 100.0))
                            .font(.largeTitle)
                            .bold()
                        Text("Goal")
                            .font(.caption)
                    }
                }
                .frame(width: 200, height: 200)
                
                // Intake Amount
                VStack {
                    Text("\(viewModel.todayIntake, specifier: "%.0f") ml")
                        .font(.system(size: 50, weight: .bold))
                    Text("Goal: \(viewModel.goal, specifier: "%.0f") ml")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Add Intake Buttons
                HStack(spacing: 20) {
                    AddAmountButton(amount: 100, viewModel: viewModel)
                    AddAmountButton(amount: 200, viewModel: viewModel)
                    AddAmountButton(amount: 500, viewModel: viewModel)
                }
                
                Spacer()
                
                // Toolbar
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            viewModel.resetTodayIntake()
                        }) {
                            Image(systemName: "arrow.counter.clockwise")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: IntakeHistoryView(history: viewModel.history)) {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Water Tracker")
        }
    }
}

struct AddAmountButton: View {
    let amount: Double
    @ObservedObject var viewModel: WaterIntakeViewModel
    
    var body: some View {
        Button(action: {
            viewModel.addIntake(amount: amount)
        }) {
            Text("+ \(amount, specifier: "%.0f") ml")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(10)
        }
    }
}

#Preview {
    ContentView()
}
