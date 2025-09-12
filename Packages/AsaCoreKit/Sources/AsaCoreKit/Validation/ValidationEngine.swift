//
//  ValidationEngine.swift
//  AsaCoreKit
//
//  統合フォーム入力検証エンジン
//

import Foundation

// MARK: - Validator Protocol

/// バリデーター基底プロトコル
public protocol Validator<Input> {
    associatedtype Input
    
    /// バリデーション実行
    /// - Parameter input: 検証対象の入力
    /// - Returns: エラーがある場合はValidationError、正常な場合はnil
    func validate(_ input: Input) -> ValidationError?
}

// MARK: - ValidationEngine

/// 統合バリデーションエンジン
public struct ValidationEngine {
    
    private init() {}
    
    // MARK: - String Validators
    
    /// 必須入力バリデーター
    public static let required = RequiredValidator()
    
    /// 最小長バリデーター
    /// - Parameter minimum: 最小文字数
    public static func minLength(_ minimum: Int) -> MinLengthValidator {
        MinLengthValidator(minimum: minimum)
    }
    
    /// 最大長バリデーター
    /// - Parameter maximum: 最大文字数
    public static func maxLength(_ maximum: Int) -> MaxLengthValidator {
        MaxLengthValidator(maximum: maximum)
    }
    
    /// メールアドレスバリデーター
    public static let email = EmailValidator()
    
    /// URLバリデーター
    public static let url = URLValidator()
    
    /// 電話番号バリデーター（日本形式）
    public static let phoneNumber = PhoneNumberValidator()
    
    // MARK: - Number Validators
    
    /// 数値バリデーター
    public static let number = NumberValidator()
    
    /// 正の数値バリデーター
    public static let positiveNumber = PositiveNumberValidator()
    
    /// 整数バリデーター
    public static let integer = IntegerValidator()
    
    /// 最小値バリデーター
    /// - Parameter minimum: 最小値
    public static func minValue(_ minimum: Double) -> MinValueValidator {
        MinValueValidator(minimum: minimum)
    }
    
    /// 最大値バリデーター
    /// - Parameter maximum: 最大値
    public static func maxValue(_ maximum: Double) -> MaxValueValidator {
        MaxValueValidator(maximum: maximum)
    }
    
    /// 値範囲バリデーター
    /// - Parameters:
    ///   - minimum: 最小値
    ///   - maximum: 最大値
    public static func range(_ minimum: Double, _ maximum: Double) -> RangeValidator {
        RangeValidator(minimum: minimum, maximum: maximum)
    }
    
    // MARK: - Date Validators
    
    /// 過去日付不可バリデーター
    public static let noFutureDate = NoFutureDateValidator()
    
    /// 未来日付不可バリデーター  
    public static let noPastDate = NoPastDateValidator()
    
    /// 日付範囲バリデーター
    /// - Parameters:
    ///   - start: 開始日
    ///   - end: 終了日
    public static func dateRange(_ start: Date, _ end: Date) -> DateRangeValidator {
        DateRangeValidator(start: start, end: end)
    }
    
    // MARK: - Composite Validation
    
    /// 複数バリデーションの実行
    /// - Parameters:
    ///   - input: 検証対象
    ///   - validators: バリデーター配列
    /// - Returns: 最初に見つかったエラー（正常な場合はnil）
    public static func validate<T>(_ input: T, with validators: [any Validator]) -> ValidationError? {
        for validator in validators {
            if let typedValidator = validator as? any Validator<T> {
                if let error = typedValidator.validate(input) {
                    return error
                }
            }
        }
        return nil
    }
    
    /// 文字列の複合バリデーション
    /// - Parameters:
    ///   - input: 検証対象文字列
    ///   - validators: 文字列バリデーター配列
    /// - Returns: エラー（正常な場合はnil）
    public static func validateString(_ input: String, with validators: [any Validator<String>]) -> ValidationError? {
        for validator in validators {
            if let error = validator.validate(input) {
                return error
            }
        }
        return nil
    }
    
    /// 数値文字列の複合バリデーション
    /// - Parameters:
    ///   - input: 検証対象文字列
    ///   - validators: バリデーター配列
    /// - Returns: エラー（正常な場合はnil）
    public static func validateNumber(_ input: String, with validators: [any Validator<String>]) -> ValidationError? {
        return validateString(input, with: validators)
    }
}

// MARK: - String Validators Implementation

/// 必須入力バリデーター
public struct RequiredValidator: Validator, Sendable {
    public func validate(_ input: String) -> ValidationError? {
        input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : nil
    }
}

/// 最小長バリデーター
public struct MinLengthValidator: Validator, Sendable {
    public let minimum: Int
    
    public func validate(_ input: String) -> ValidationError? {
        input.count < minimum ? .tooShort(minimum: minimum) : nil
    }
}

/// 最大長バリデーター
public struct MaxLengthValidator: Validator, Sendable {
    public let maximum: Int
    
    public func validate(_ input: String) -> ValidationError? {
        input.count > maximum ? .tooLong(maximum: maximum) : nil
    }
}

/// メールアドレスバリデーター
public struct EmailValidator: Validator, Sendable {
    private let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    
    public func validate(_ input: String) -> ValidationError? {
        let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: input) ? nil : .invalidEmail
    }
}

/// URLバリデーター
public struct URLValidator: Validator, Sendable {
    public func validate(_ input: String) -> ValidationError? {
        URL(string: input) != nil ? nil : .invalidURL
    }
}

/// 電話番号バリデーター（日本形式）
public struct PhoneNumberValidator: Validator, Sendable {
    private let phoneRegex = "^[0-9-+()\\s]*$"
    
    public func validate(_ input: String) -> ValidationError? {
        let predicate = NSPredicate(format:"SELF MATCHES %@", phoneRegex)
        let hasMinLength = input.count >= 10
        return predicate.evaluate(with: input) && hasMinLength ? nil : .invalidPhoneNumber
    }
}

// MARK: - Number Validators Implementation

/// 数値バリデーター
public struct NumberValidator: Validator, Sendable {
    public func validate(_ input: String) -> ValidationError? {
        Double(input) != nil ? nil : .notANumber
    }
}

/// 正の数値バリデーター
public struct PositiveNumberValidator: Validator, Sendable {
    public func validate(_ input: String) -> ValidationError? {
        guard let number = Double(input) else { return .notANumber }
        return number > 0 ? nil : .notPositive
    }
}

/// 整数バリデーター
public struct IntegerValidator: Validator, Sendable {
    public func validate(_ input: String) -> ValidationError? {
        Int(input) != nil ? nil : .notInteger
    }
}

/// 最小値バリデーター
public struct MinValueValidator: Validator, Sendable {
    public let minimum: Double
    
    public func validate(_ input: String) -> ValidationError? {
        guard let number = Double(input) else { return .notANumber }
        return number >= minimum ? nil : .tooSmall(minimum: minimum)
    }
}

/// 最大値バリデーター
public struct MaxValueValidator: Validator, Sendable {
    public let maximum: Double
    
    public func validate(_ input: String) -> ValidationError? {
        guard let number = Double(input) else { return .notANumber }
        return number <= maximum ? nil : .tooLarge(maximum: maximum)
    }
}

/// 値範囲バリデーター
public struct RangeValidator: Validator, Sendable {
    public let minimum: Double
    public let maximum: Double
    
    public func validate(_ input: String) -> ValidationError? {
        guard let number = Double(input) else { return .notANumber }
        if number < minimum { return .tooSmall(minimum: minimum) }
        if number > maximum { return .tooLarge(maximum: maximum) }
        return nil
    }
}

// MARK: - Date Validators Implementation

/// 未来日付不可バリデーター
public struct NoFutureDateValidator: Validator, Sendable {
    public func validate(_ input: Date) -> ValidationError? {
        input > Date() ? .futureDateNotAllowed : nil
    }
}

/// 過去日付不可バリデーター
public struct NoPastDateValidator: Validator, Sendable {
    public func validate(_ input: Date) -> ValidationError? {
        input < Date() ? .pastDateNotAllowed : nil
    }
}

/// 日付範囲バリデーター
public struct DateRangeValidator: Validator, Sendable {
    public let start: Date
    public let end: Date
    
    public func validate(_ input: Date) -> ValidationError? {
        (start...end).contains(input) ? nil : .dateOutOfRange(start: start, end: end)
    }
}