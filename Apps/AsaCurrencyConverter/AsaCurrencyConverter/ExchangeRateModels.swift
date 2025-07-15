//
//  ExchangeRateModels.swift
//  AsaCurrencyConverter
//  
//  Created on 2025/07/15
//

import Foundation

// MARK: - ExchangeRate-API Response Models
struct ExchangeRateResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}

// MARK: - Currency Information
struct Currency: Identifiable, Codable {
    let id: String
    let name: String
    let symbol: String
    
    init(code: String, name: String, symbol: String) {
        self.id = code
        self.name = name
        self.symbol = symbol
    }
}

// MARK: - Currency Data
class CurrencyData {
    static let popularCurrencies: [Currency] = [
        Currency(code: "USD", name: "米ドル", symbol: "$"),
        Currency(code: "EUR", name: "ユーロ", symbol: "€"),
        Currency(code: "JPY", name: "日本円", symbol: "¥"),
        Currency(code: "GBP", name: "イギリスポンド", symbol: "£"),
        Currency(code: "CNY", name: "中国人民元", symbol: "¥"),
        Currency(code: "KRW", name: "韓国ウォン", symbol: "₩"),
        Currency(code: "AUD", name: "オーストラリアドル", symbol: "A$"),
        Currency(code: "CAD", name: "カナダドル", symbol: "C$"),
        Currency(code: "CHF", name: "スイスフラン", symbol: "Fr"),
        Currency(code: "SGD", name: "シンガポールドル", symbol: "S$"),
        Currency(code: "THB", name: "タイバーツ", symbol: "฿"),
        Currency(code: "HKD", name: "香港ドル", symbol: "HK$"),
        Currency(code: "TWD", name: "台湾ドル", symbol: "NT$"),
        Currency(code: "INR", name: "インドルピー", symbol: "₹"),
        Currency(code: "BRL", name: "ブラジルレアル", symbol: "R$"),
        Currency(code: "RUB", name: "ロシアルーブル", symbol: "₽"),
        Currency(code: "ZAR", name: "南アフリカランド", symbol: "R"),
        Currency(code: "MXN", name: "メキシコペソ", symbol: "Mex$"),
        Currency(code: "TRY", name: "トルコリラ", symbol: "₺"),
        Currency(code: "NZD", name: "ニュージーランドドル", symbol: "NZ$")
    ]
    
    static func getCurrency(by code: String) -> Currency? {
        return popularCurrencies.first { $0.id == code }
    }
    
    static func getCurrencyName(by code: String) -> String {
        return getCurrency(by: code)?.name ?? code
    }
    
    static func getCurrencySymbol(by code: String) -> String {
        return getCurrency(by: code)?.symbol ?? code
    }
}

// MARK: - Conversion Result
struct ConversionResult {
    let fromCurrency: String
    let toCurrency: String
    let amount: Double
    let convertedAmount: Double
    let rate: Double
    let timestamp: Date
    
    init(fromCurrency: String, toCurrency: String, amount: Double, convertedAmount: Double, rate: Double) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.amount = amount
        self.convertedAmount = convertedAmount
        self.rate = rate
        self.timestamp = Date()
    }
}