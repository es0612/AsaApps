//
//  ConversionHistory.swift
//  AsaCurrencyConverter
//  
//  Created on 2025/07/15
//

import Foundation
import SwiftData

@Model
final class ConversionHistory {
    var fromCurrency: String
    var toCurrency: String
    var amount: Double
    var convertedAmount: Double
    var rate: Double
    var timestamp: Date
    
    init(fromCurrency: String, toCurrency: String, amount: Double, convertedAmount: Double, rate: Double) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.amount = amount
        self.convertedAmount = convertedAmount
        self.rate = rate
        self.timestamp = Date()
    }
}
