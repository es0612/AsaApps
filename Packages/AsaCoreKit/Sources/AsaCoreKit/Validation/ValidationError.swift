//
//  ValidationError.swift
//  AsaCoreKit
//
//  バリデーション専用エラー定義
//

import Foundation

/// バリデーション結果エラー
public enum ValidationError: Error, LocalizedError, Equatable {
    
    // MARK: - 基本バリデーション
    case empty
    case tooShort(minimum: Int)
    case tooLong(maximum: Int)
    case invalidFormat
    
    // MARK: - 数値バリデーション
    case notANumber
    case tooSmall(minimum: Double)
    case tooLarge(maximum: Double)
    case notPositive
    case notInteger
    
    // MARK: - 文字列バリデーション
    case invalidEmail
    case invalidURL
    case invalidPhoneNumber
    case containsInvalidCharacters(allowed: String)
    
    // MARK: - 日付バリデーション
    case invalidDate
    case pastDateNotAllowed
    case futureDateNotAllowed
    case dateOutOfRange(start: Date, end: Date)
    
    // MARK: - カスタムバリデーション
    case custom(String)
    
    // MARK: - LocalizedError Implementation
    
    public var errorDescription: String? {
        switch self {
        // 基本
        case .empty:
            return "入力が空です"
        case .tooShort(let minimum):
            return "\(minimum)文字以上で入力してください"
        case .tooLong(let maximum):
            return "\(maximum)文字以下で入力してください"
        case .invalidFormat:
            return "形式が正しくありません"
            
        // 数値
        case .notANumber:
            return "数値で入力してください"
        case .tooSmall(let minimum):
            return "\(minimum)以上の値を入力してください"
        case .tooLarge(let maximum):
            return "\(maximum)以下の値を入力してください"
        case .notPositive:
            return "正の値を入力してください"
        case .notInteger:
            return "整数で入力してください"
            
        // 文字列
        case .invalidEmail:
            return "有効なメールアドレスを入力してください"
        case .invalidURL:
            return "有効なURLを入力してください"
        case .invalidPhoneNumber:
            return "有効な電話番号を入力してください"
        case .containsInvalidCharacters(let allowed):
            return "使用できる文字: \(allowed)"
            
        // 日付
        case .invalidDate:
            return "有効な日付を入力してください"
        case .pastDateNotAllowed:
            return "過去の日付は入力できません"
        case .futureDateNotAllowed:
            return "未来の日付は入力できません"
        case .dateOutOfRange(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: start))から\(formatter.string(from: end))の間で入力してください"
            
        // カスタム
        case .custom(let message):
            return message
        }
    }
}