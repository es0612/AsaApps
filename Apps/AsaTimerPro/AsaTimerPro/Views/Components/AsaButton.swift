//
//  AsaButton.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//  ブランドガイドライン準拠のボタンコンポーネント
//

import SwiftUI

struct AsaButton: View {
    let title: String
    let action: () -> Void
    let color: Color
    let isEnabled: Bool

    // MARK: - Init
    init(
        title: String, 
        action: @escaping () -> Void, 
        color: Color = Color("AsaCoffeeBrown"), 
        isEnabled: Bool = true
    ) {
        self.title = title
        self.action = action
        self.color = color
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isEnabled ? color : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                .scaleEffect(isEnabled ? 1.0 : 0.95)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        AsaButton(title: "テストボタン", action: {})
        AsaButton(title: "無効ボタン", action: {}, isEnabled: false)
        AsaButton(title: "カスタムカラー", action: {}, color: Color("AsaMocha"))
    }
    .padding()
}