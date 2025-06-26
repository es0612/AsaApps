//
//  ContentView.swift
//  AsaWaterTracker
//  
//  Created on 2025/06/26
//


import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WaterIntakeViewModel()
    @State private var showingCustomAmountAlert = false
    @State private var showingGoalAlert = false
    @State private var customAmount: String = ""
    @State private var newGoal: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color("AsaSoftCream").edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Spacer()

                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 25)
                            .opacity(0.2)
                            .foregroundColor(Color("AsaMocha"))

                        Circle()
                            .trim(from: 0.0, to: CGFloat(min(viewModel.progress, 1.0)))
                            .stroke(style: StrokeStyle(lineWidth: 25, lineCap: .round, lineJoin: .round))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.spring(), value: viewModel.progress)

                        VStack {
                            Text(String(format: "%.0f %%", min(viewModel.progress, 1.0) * 100.0))
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(Color("AsaDarkSlate"))
                            Text("達成率")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 220, height: 220)

                    // Intake Amount
                    VStack {
                        Text("\(viewModel.todayIntake, specifier: "%.0f") ml")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(Color("AsaDarkSlate"))
                        Text("目標: \(viewModel.goal, specifier: "%.0f") ml")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .onTapGesture {
                                newGoal = String(format: "%.0f", viewModel.goal)
                                showingGoalAlert = true
                            }
                    }

                    Spacer()

                    // Add Intake Buttons
                    VStack(spacing: 15) {
                        HStack(spacing: 15) {
                            AddAmountButton(amount: 100, viewModel: viewModel)
                            AddAmountButton(amount: 200, viewModel: viewModel)
                        }
                        HStack(spacing: 15) {
                            AddAmountButton(amount: 300, viewModel: viewModel)
                            AddAmountButton(amount: 500, viewModel: viewModel)
                        }
                        Button(action: {
                            customAmount = ""
                            showingCustomAmountAlert = true
                        }) {
                            Text("カスタム量を入力")
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color("AsaMutedSage"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("水分補給トラッカー")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.resetTodayIntake()
                    }) {
                        Image(systemName: "arrow.counter.clockwise.circle.fill")
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: IntakeHistoryView(history: viewModel.history)) {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.title2)
                    }
                }
            }
            .alert("カスタム量を入力", isPresented: $showingCustomAmountAlert) {
                TextField("例: 250", text: $customAmount)
                    .keyboardType(.numberPad)
                Button("追加") {
                    if let amount = Double(customAmount) {
                        viewModel.addIntake(amount: amount)
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("摂取した水分量（ml）を入力してください。")
            }
            .alert("目標を設定", isPresented: $showingGoalAlert) {
                TextField("例: 2500", text: $newGoal)
                    .keyboardType(.numberPad)
                Button("保存") {
                    if let goal = Double(newGoal) {
                        viewModel.updateGoal(newGoal: goal)
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("1日の目標水分量（ml）を入力してください。")
            }
        }
        .accentColor(Color("AsaCoffeeBrown"))
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
                .font(.headline)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(Color("AsaSoftCream"))
                .foregroundColor(Color("AsaDarkSlate"))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
        }
    }
}

#Preview {
    ContentView()
}