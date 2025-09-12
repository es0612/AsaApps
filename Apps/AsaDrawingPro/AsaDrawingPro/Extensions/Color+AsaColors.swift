//
//  Color+AsaColors.swift
//  AsaDrawingPro
//  
//  Created on 2025/09/12
//

import SwiftUI

extension Color {
    // AsaAppsブランドカラー
    static let asaCoffeeBrown = Color(red: 198/255, green: 140/255, blue: 83/255)
    static let asaMocha = Color(red: 139/255, green: 90/255, blue: 43/255)
    static let asaSoftCream = Color(red: 232/255, green: 213/255, blue: 185/255)
    static let asaDarkSlate = Color(red: 47/255, green: 62/255, blue: 70/255)
    static let asaMutedSage = Color(red: 122/255, green: 145/255, blue: 141/255)
    
    // プリセットカラー
    static let presetColors: [Color] = [
        .asaCoffeeBrown,
        .asaMocha,
        .black,
        .gray,
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .purple
    ]
}