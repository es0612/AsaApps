//
//  AsaCoreError.swift
//  AsaCoreKit
//
//  AsaCoreKit統一エラー定義
//

import Foundation

/// AsaCoreKit統一エラー型
public enum AsaCoreError: Error, LocalizedError, Equatable {
    
    // MARK: - Data Persistence Errors
    case persistenceError(String)
    case dataCorruption(String)
    case encodingFailed
    case decodingFailed
    
    // MARK: - Validation Errors  
    case validationFailed(String)
    case invalidInput(field: String, reason: String)
    case requiredFieldEmpty(String)
    
    // MARK: - CRUD Operation Errors
    case itemNotFound(String)
    case duplicateItem(String)
    case operationFailed(String)
    
    // MARK: - Generic Errors
    case unknownError(String)
    case configurationError(String)
    
    // MARK: - LocalizedError Implementation
    
    public var errorDescription: String? {
        switch self {
        // Persistence
        case .persistenceError(let message):
            return "データ保存エラー: \(message)"
        case .dataCorruption(let message):
            return "データ破損: \(message)"
        case .encodingFailed:
            return "データエンコードに失敗しました"
        case .decodingFailed:
            return "データデコードに失敗しました"
            
        // Validation
        case .validationFailed(let message):
            return "入力検証エラー: \(message)"
        case .invalidInput(let field, let reason):
            return "\(field)の入力が無効です: \(reason)"
        case .requiredFieldEmpty(let field):
            return "\(field)は必須項目です"
            
        // CRUD Operations
        case .itemNotFound(let item):
            return "\(item)が見つかりません"
        case .duplicateItem(let item):
            return "\(item)は既に存在します"
        case .operationFailed(let operation):
            return "\(operation)操作に失敗しました"
            
        // Generic
        case .unknownError(let message):
            return "不明なエラー: \(message)"
        case .configurationError(let message):
            return "設定エラー: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .persistenceError, .dataCorruption:
            return "アプリを再起動してください"
        case .encodingFailed, .decodingFailed:
            return "データ形式を確認してください"
        case .validationFailed, .invalidInput, .requiredFieldEmpty:
            return "入力内容を確認して再度お試しください"
        case .itemNotFound:
            return "項目が存在するか確認してください"
        case .duplicateItem:
            return "別の名前や値を使用してください"
        case .operationFailed:
            return "しばらく待ってから再度お試しください"
        case .unknownError, .configurationError:
            return "アプリを再起動するか、サポートにお問い合わせください"
        }
    }
}