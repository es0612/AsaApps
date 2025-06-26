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
            ScrollView {
                VStack(spacing: 20) {
                    // 時間設定セクション
                    AsaCard {
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Text("睡眠時間")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Spacer()
                            }
                            
                            // 就寝時間
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Image(systemName: "moon.fill")
                                        .foregroundColor(Color("AsaMutedSage"))
                                        .font(.caption)
                                    Text("就寝時間")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                DatePicker("", selection: $viewModel.bedTime, displayedComponents: [.hourAndMinute])
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                            }
                            
                            Divider()
                            
                            // 起床時間
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Image(systemName: "sun.max.fill")
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                        .font(.caption)
                                    Text("起床時間")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                DatePicker("", selection: $viewModel.wakeTime, displayedComponents: [.hourAndMinute])
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                            }
                            
                            // 睡眠時間表示
                            if viewModel.wakeTime > viewModel.bedTime {
                                HStack {
                                    Text("睡眠時間:")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(calculateSleepDuration())
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                }
                                .padding(.top, 10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 睡眠の質セクション
                    AsaCard {
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Text("睡眠の質")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Spacer()
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                                ForEach(SleepQuality.allCases, id: \.self) { quality in
                                    QualityButton(
                                        quality: quality,
                                        isSelected: viewModel.selectedQuality == quality
                                    ) {
                                        viewModel.selectedQuality = quality
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // メモセクション
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
                            
                            TextField("睡眠に関するメモを入力...", text: $viewModel.notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 保存ボタン
                    AsaButton(title: "記録を保存", 
                             isEnabled: viewModel.wakeTime > viewModel.bedTime) {
                        viewModel.addSleepLog()
                        dismiss()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("睡眠記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .background(Color("AsaSoftCream").opacity(0.3))
        }
    }
    
    private func calculateSleepDuration() -> String {
        let duration = viewModel.wakeTime.timeIntervalSince(viewModel.bedTime)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)時間\(minutes)分"
    }
}

struct QualityButton: View {
    let quality: SleepQuality
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(quality.emoji)
                    .font(.title2)
                Text(quality.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
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

#Preview {
    AddSleepLogView(viewModel: SleepLogViewModel())
}