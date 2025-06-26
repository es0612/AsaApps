//
//  SleepQualitySection.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct SleepQualitySection: View {
    @Binding var selectedQuality: SleepQuality
    
    var body: some View {
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
                            isSelected: selectedQuality == quality
                        ) {
                            selectedQuality = quality
                        }
                    }
                }
            }
        }
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
    SleepQualitySection(selectedQuality: .constant(.normal))
        .padding()
}