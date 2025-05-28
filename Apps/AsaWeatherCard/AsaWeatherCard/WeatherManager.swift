//
//  WeatherManager.swift
//  AsaWeatherCard
//  
//  Created on 2025/05/29
//


import SwiftUI

class WeatherManager: ObservableObject {
    @Published var weatherData: WeatherData = WeatherData(
        city: "Tokyo",
        temperature: 22,
        condition: "Sunny",
        iconName: "sun.max.fill"
    )
}
