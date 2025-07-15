//
//  CurrencyService.swift
//  AsaCurrencyConverter
//  
//  Created on 2025/07/15
//

import Foundation
import SwiftUI

// MARK: - Network Error Types
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .noData:
            return "データが取得できませんでした"
        case .decodingError:
            return "データの解析に失敗しました"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        }
    }
}

// MARK: - Currency Service
@Observable
class CurrencyService {
    private let baseURL = "https://api.exchangerate-api.com/v4/latest/"
    private let session = URLSession.shared
    
    var isLoading = false
    var errorMessage: String?
    var lastUpdateTime: Date?
    
    // MARK: - Fetch Exchange Rates
    func fetchExchangeRates(for baseCurrency: String = "USD") async throws -> ExchangeRateResponse {
        guard let url = URL(string: baseURL + baseCurrency) else {
            throw NetworkError.invalidURL
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            
            await MainActor.run {
                self.lastUpdateTime = Date()
                self.isLoading = false
            }
            
            return response
        } catch {
            await MainActor.run {
                self.isLoading = false
                if error is DecodingError {
                    self.errorMessage = NetworkError.decodingError.localizedDescription
                } else {
                    self.errorMessage = NetworkError.networkError(error).localizedDescription
                }
            }
            throw error
        }
    }
    
    // MARK: - Convert Currency
    func convertCurrency(amount: Double, from fromCurrency: String, to toCurrency: String) async throws -> ConversionResult {
        let response = try await fetchExchangeRates(for: fromCurrency)
        
        guard let rate = response.rates[toCurrency] else {
            throw NetworkError.decodingError
        }
        
        let convertedAmount = amount * rate
        
        return ConversionResult(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            amount: amount,
            convertedAmount: convertedAmount,
            rate: rate
        )
    }
    
    // MARK: - Get All Rates for Base Currency
    func getAllRates(for baseCurrency: String = "USD") async throws -> [String: Double] {
        let response = try await fetchExchangeRates(for: baseCurrency)
        return response.rates
    }
    
    // MARK: - Clear Error
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Singleton Instance
extension CurrencyService {
    static let shared = CurrencyService()
}