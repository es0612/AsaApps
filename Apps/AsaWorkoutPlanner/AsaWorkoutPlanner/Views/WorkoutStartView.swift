//
//  WorkoutStartView.swift
//  AsaWorkoutPlanner
//
//  ワークアウト開始画面
//

import SwiftUI
import AsaUIKit

struct WorkoutStartView: View {
    // MARK: - Properties
    
    @Bindable var viewModel: WorkoutPlannerViewModel
    @State private var selectedPlan: WorkoutPlan?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.hasActiveSession {
                    activeSessionView
                } else {
                    startNewSessionView
                }
            }
            .padding()
            .navigationTitle("ワークアウト")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Components
    
    private var activeSessionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(AsaColors.coffeeBrown))
            
            Text("セッション進行中")
                .font(.title2)
                .fontWeight(.bold)
            
            if let session = viewModel.currentSession {
                Text(session.workoutPlan?.name ?? "ワークアウト")
                    .font(.headline)
                    .foregroundColor(Color(AsaColors.mutedSage))
                
                Text(session.displayDuration)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .monospacedDigit()
                
                HStack(spacing: 20) {
                    AsaButton(
                        title: session.isPaused ? "再開" : "一時停止",
                        action: {
                            if session.isPaused {
                                viewModel.resumeSession()
                            } else {
                                viewModel.pauseSession()
                            }
                        },
                        color: AsaColors.softCream
                    )
                    
                    AsaButton(
                        title: "完了",
                        action: {
                            viewModel.completeSession()
                        },
                        color: AsaColors.coffeeBrown
                    )
                }
                
                Button("キャンセル") {
                    viewModel.cancelSession()
                }
                .foregroundColor(.red)
            }
        }
    }
    
    private var startNewSessionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "play.circle")
                .font(.system(size: 60))
                .foregroundColor(Color(AsaColors.mutedSage))
            
            Text("ワークアウトを開始")
                .font(.title2)
                .fontWeight(.bold)
            
            if let todaysWorkout = viewModel.todaysWorkout {
                VStack(spacing: 12) {
                    Text("今日の予定")
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                    
                    PlanSelectionCard(
                        plan: todaysWorkout,
                        isSelected: selectedPlan?.id == todaysWorkout.id,
                        action: {
                            selectedPlan = todaysWorkout
                        }
                    )
                }
            }
            
            if !viewModel.workoutPlans.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("プランを選択")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewModel.workoutPlans) { plan in
                                PlanSelectionCard(
                                    plan: plan,
                                    isSelected: selectedPlan?.id == plan.id,
                                    action: {
                                        selectedPlan = plan
                                    }
                                )
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            AsaButton(
                title: "開始",
                action: {
                    if let plan = selectedPlan {
                        viewModel.startWorkoutSession(with: plan)
                    }
                },
                color: AsaColors.coffeeBrown
            )
            .disabled(selectedPlan == nil)
        }
    }
}

struct PlanSelectionCard: View {
    let plan: WorkoutPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            AsaCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Label("\(plan.totalExercises)種目", systemImage: "figure.strengthtraining.traditional")
                            Text("•")
                            Text("\(Int(plan.estimatedDuration))分")
                        }
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                    }
                }
                .padding()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(AsaColors.coffeeBrown) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}