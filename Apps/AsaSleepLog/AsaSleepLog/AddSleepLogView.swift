//
//  AddSleepLogView.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct AddSleepLogView: View {
    @ObservedObject var viewModel: SleepLogViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScrollView {
                    VStack(spacing: 20) {
                        TimeSettingSection(
                            bedTime: $viewModel.bedTime,
                            wakeTime: $viewModel.wakeTime
                        )
                        .padding(.horizontal)
                        
                        SleepQualitySection(selectedQuality: $viewModel.selectedQuality)
                            .padding(.horizontal)
                        
                        MoodRatingSection(selectedMood: $viewModel.selectedMood)
                            .padding(.horizontal)
                        
                        // 詳細オプション
                        AdvancedOptionsSection(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        NotesSection(notes: $viewModel.notes)
                            .padding(.horizontal)
                    }
                }
                
                AsaButton(title: "記録を保存") {
                    viewModel.addSleepLog()
                    dismiss()
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("睡眠記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MoodRatingSection: View {
    @Binding var selectedMood: MoodRating?
    
    var body: some View {
        AsaCard {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "face.smiling")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("朝の気分")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                    ForEach(MoodRating.allCases, id: \.self) { mood in
                        MoodButton(
                            mood: mood,
                            isSelected: selectedMood == mood
                        ) {
                            selectedMood = selectedMood == mood ? nil : mood
                        }
                    }
                }
            }
        }
    }
}

struct MoodButton: View {
    let mood: MoodRating
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title3)
            }
            .frame(width: 50, height: 50)
            .background(
                isSelected ? Color("AsaCoffeeBrown") : Color.gray.opacity(0.1)
            )
            .foregroundColor(
                isSelected ? .white : Color("AsaCoffeeBrown")
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color("AsaCoffeeBrown") : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct AdvancedOptionsSection: View {
    @ObservedObject var viewModel: SleepLogViewModel
    
    var body: some View {
        AsaCard {
            VStack(spacing: 15) {
                Button(action: {
                    withAnimation {
                        viewModel.showAdvancedOptions.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        Text("詳細オプション")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        Spacer()
                        Image(systemName: viewModel.showAdvancedOptions ? "chevron.up" : "chevron.down")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                if viewModel.showAdvancedOptions {
                    VStack(spacing: 15) {
                        // 入眠時間
                        HStack {
                            Image(systemName: "zzz")
                                .foregroundColor(Color("AsaMutedSage"))
                                .font(.caption)
                            Text("入眠時間")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            DatePicker("", selection: $viewModel.fellAsleepTime, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .scaleEffect(0.9)
                        }
                        
                        // 夜中に起きた回数
                        HStack {
                            Image(systemName: "eye")
                                .foregroundColor(Color("AsaMutedSage"))
                                .font(.caption)
                            Text("夜中に起きた回数")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Stepper("\(viewModel.wakeUpCount)回", value: $viewModel.wakeUpCount, in: 0...10)
                                .frame(width: 120)
                        }
                    }
                }
            }
        }
    }
}

struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        AsaCard {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("メモ（任意）")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                }
                
                TextField("睡眠に関するメモを入力...", text: $notes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
    }
}

#Preview {
    AddSleepLogView(viewModel: SleepLogViewModel())
}