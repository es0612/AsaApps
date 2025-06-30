//
//  WorkoutHistoryView.swift
//  AsaWorkoutLog
//  
//  Created on 2025/07/01
//

import SwiftUI

struct WorkoutHistoryView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var searchText = ""
    @State private var selectedWorkoutType: WorkoutType?
    
    var filteredSessions: [WorkoutSession] {
        var sessions = viewModel.workoutSessions
        
        // 運動種類でフィルター
        if let selectedType = selectedWorkoutType {
            sessions = sessions.filter { $0.workoutType == selectedType }
        }
        
        // 検索テキストでフィルター
        if !searchText.isEmpty {
            sessions = sessions.filter { session in
                session.workoutType.displayName.localizedCaseInsensitiveContains(searchText) ||
                (session.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return sessions
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // フィルターセクション
            VStack(spacing: 12) {
                // 検索バー
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("運動を検索", text: $searchText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // 運動種類フィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // すべて表示ボタン
                        Button(action: {
                            selectedWorkoutType = nil
                        }) {
                            Text("すべて")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedWorkoutType == nil ? Color("AsaCoffeeBrown") : Color(.systemGray5))
                                .foregroundColor(selectedWorkoutType == nil ? .white : .primary)
                                .cornerRadius(16)
                        }
                        
                        // 各運動種類ボタン
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Button(action: {
                                selectedWorkoutType = type
                            }) {
                                HStack(spacing: 4) {
                                    Text(type.emoji)
                                    Text(type.displayName)
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedWorkoutType == type ? Color("AsaCoffeeBrown") : Color(.systemGray5))
                                .foregroundColor(selectedWorkoutType == type ? .white : .primary)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            Divider()
            
            // 運動履歴リスト
            if filteredSessions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 50))
                        .foregroundColor(Color("AsaMutedSage").opacity(0.5))
                    
                    if searchText.isEmpty && selectedWorkoutType == nil {
                        Text("運動記録がありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("最初の運動を記録してみましょう！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("条件に一致する記録がありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("フィルターを変更してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredSessions) { session in
                        WorkoutHistoryRowView(session: session)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete(perform: deleteWorkouts)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("運動履歴")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("編集") {
            // 編集モードの実装は省略
        })
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        let sessionsToDelete = offsets.map { filteredSessions[$0] }
        for session in sessionsToDelete {
            viewModel.deleteWorkoutSession(session)
        }
    }
}

struct WorkoutHistoryRowView: View {
    let session: WorkoutSession
    
    var body: some View {
        AsaCard {
            HStack(spacing: 12) {
                // 運動種類アイコン
                VStack {
                    Text(session.workoutType.emoji)
                        .font(.title)
                    Text(session.intensity.emoji)
                        .font(.caption)
                }
                
                // 運動詳細
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workoutType.displayName)
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("\(session.dateFormatted) • \(session.timeFormatted)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Label(session.durationFormatted, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Label(session.intensity.displayName, systemImage: "flame")
                            .font(.caption)
                            .foregroundColor(Color(session.intensity.color))
                        
                        if let calories = session.caloriesBurned {
                            Label("\(calories)kcal", systemImage: "bolt")
                                .font(.caption)
                                .foregroundColor(Color("AsaMocha"))
                        }
                    }
                    
                    if let notes = session.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationView {
        WorkoutHistoryView(viewModel: WorkoutViewModel())
    }
}