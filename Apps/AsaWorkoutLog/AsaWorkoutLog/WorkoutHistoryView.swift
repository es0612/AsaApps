//
//  WorkoutHistoryView.swift
//  AsaWorkoutLog
//
//  Created on 2025/07/03
//

import SwiftUI

struct WorkoutHistoryView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var showingAddWorkout = false
    @State private var selectedCategory: WorkoutCategory? = nil
    
    var filteredWorkouts: [Workout] {
        if let selectedCategory = selectedCategory {
            return viewModel.workouts.filter { $0.category == selectedCategory }
        }
        return viewModel.workouts
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // カテゴリフィルター
                if !viewModel.workouts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryFilterButton(
                                title: "すべて",
                                isSelected: selectedCategory == nil,
                                color: Color("AsaCoffeeBrown")
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(WorkoutCategory.allCases, id: \.self) { category in
                                CategoryFilterButton(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    color: category.color
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // ワークアウトリスト
                if filteredWorkouts.isEmpty {
                    VStack(spacing: 20) {
                        Text("🏃‍♂️")
                            .font(.system(size: 60))
                        
                        Text(selectedCategory == nil ? "まだワークアウトがありません" : "このカテゴリのワークアウトがありません")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        AsaButton(title: "最初のワークアウトを追加") {
                            showingAddWorkout = true
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(groupedWorkouts.keys.sorted(by: >), id: \.self) { date in
                            Section(header: Text(formatSectionDate(date))) {
                                ForEach(groupedWorkouts[date] ?? []) { workout in
                                    WorkoutHistoryRow(workout: workout)
                                }
                                .onDelete { indexSet in
                                    deleteWorkouts(at: indexSet, for: date)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddWorkout = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddWorkout) {
            AddWorkoutView(viewModel: viewModel)
        }
    }
    
    private var groupedWorkouts: [String: [Workout]] {
        Dictionary(grouping: filteredWorkouts.sorted(by: { $0.date > $1.date })) { workout in
            formatDateKey(workout.date)
        }
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatSectionDate(_ dateKey: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateKey) else {
            return dateKey
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "M月d日 (E)"
        outputFormatter.locale = Locale(identifier: "ja_JP")
        
        return outputFormatter.string(from: date)
    }
    
    private func deleteWorkouts(at offsets: IndexSet, for dateKey: String) {
        let workoutsForDate = groupedWorkouts[dateKey] ?? []
        
        for index in offsets {
            let workout = workoutsForDate[index]
            viewModel.deleteWorkout(workout)
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct WorkoutHistoryRow: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: workout.category.icon)
                        .foregroundColor(workout.category.color)
                        .frame(width: 16)
                    
                    Text(workout.name)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Text(formatTime(workout.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !workout.notes.isEmpty {
                    Text(workout.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(workout.formattedDuration)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text(workout.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    WorkoutHistoryView(viewModel: WorkoutViewModel())
}