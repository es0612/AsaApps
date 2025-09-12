//
//  ValidationEngineTests.swift
//  AsaCoreKitTests
//
//  ValidationEngineテスト
//

import Testing
import Foundation
@testable import AsaCoreKit

struct ValidationEngineTests {
    
    // MARK: - String Validation Tests
    
    @Test("必須入力バリデーションテスト")
    func testRequiredValidator() {
        let validator = ValidationEngine.required
        
        // 正常ケース
        #expect(validator.validate("有効な入力") == nil)
        
        // エラーケース
        #expect(validator.validate("") == .empty)
        #expect(validator.validate("   ") == .empty)
        #expect(validator.validate("\n\t  ") == .empty)
    }
    
    @Test("最小長バリデーションテスト")
    func testMinLengthValidator() {
        let validator = ValidationEngine.minLength(5)
        
        // 正常ケース
        #expect(validator.validate("12345") == nil)
        #expect(validator.validate("123456") == nil)
        
        // エラーケース
        #expect(validator.validate("1234") == .tooShort(minimum: 5))
        #expect(validator.validate("") == .tooShort(minimum: 5))
    }
    
    @Test("最大長バリデーションテスト")
    func testMaxLengthValidator() {
        let validator = ValidationEngine.maxLength(10)
        
        // 正常ケース
        #expect(validator.validate("12345") == nil)
        #expect(validator.validate("1234567890") == nil)
        
        // エラーケース
        #expect(validator.validate("12345678901") == .tooLong(maximum: 10))
    }
    
    @Test("メールアドレスバリデーションテスト")
    func testEmailValidator() {
        let validator = ValidationEngine.email
        
        // 正常ケース
        #expect(validator.validate("test@example.com") == nil)
        #expect(validator.validate("user.name+tag@domain.co.jp") == nil)
        
        // エラーケース
        #expect(validator.validate("invalid-email") == .invalidEmail)
        #expect(validator.validate("@domain.com") == .invalidEmail)
        #expect(validator.validate("test@") == .invalidEmail)
    }
    
    @Test("URLバリデーションテスト")  
    func testURLValidator() {
        let validator = ValidationEngine.url
        
        // 正常ケース
        #expect(validator.validate("https://www.example.com") == nil)
        #expect(validator.validate("http://localhost:8080") == nil)
        
        // エラーケース
        #expect(validator.validate("invalid-url") == .invalidURL)
        #expect(validator.validate("") == .invalidURL)
    }
    
    // MARK: - Number Validation Tests
    
    @Test("数値バリデーションテスト")
    func testNumberValidator() {
        let validator = ValidationEngine.number
        
        // 正常ケース
        #expect(validator.validate("123") == nil)
        #expect(validator.validate("123.45") == nil)
        #expect(validator.validate("-123.45") == nil)
        
        // エラーケース
        #expect(validator.validate("abc") == .notANumber)
        #expect(validator.validate("123abc") == .notANumber)
        #expect(validator.validate("") == .notANumber)
    }
    
    @Test("正の数値バリデーションテスト")
    func testPositiveNumberValidator() {
        let validator = ValidationEngine.positiveNumber
        
        // 正常ケース
        #expect(validator.validate("1") == nil)
        #expect(validator.validate("123.45") == nil)
        
        // エラーケース
        #expect(validator.validate("0") == .notPositive)
        #expect(validator.validate("-1") == .notPositive)
        #expect(validator.validate("abc") == .notANumber)
    }
    
    @Test("整数バリデーションテスト")
    func testIntegerValidator() {
        let validator = ValidationEngine.integer
        
        // 正常ケース
        #expect(validator.validate("123") == nil)
        #expect(validator.validate("-123") == nil)
        
        // エラーケース
        #expect(validator.validate("123.45") == .notInteger)
        #expect(validator.validate("abc") == .notInteger)
    }
    
    @Test("最小値バリデーションテスト")
    func testMinValueValidator() {
        let validator = ValidationEngine.minValue(10.0)
        
        // 正常ケース
        #expect(validator.validate("10") == nil)
        #expect(validator.validate("20") == nil)
        
        // エラーケース
        #expect(validator.validate("9") == .tooSmall(minimum: 10.0))
        #expect(validator.validate("abc") == .notANumber)
    }
    
    @Test("最大値バリデーションテスト")
    func testMaxValueValidator() {
        let validator = ValidationEngine.maxValue(100.0)
        
        // 正常ケース
        #expect(validator.validate("50") == nil)
        #expect(validator.validate("100") == nil)
        
        // エラーケース
        #expect(validator.validate("101") == .tooLarge(maximum: 100.0))
        #expect(validator.validate("abc") == .notANumber)
    }
    
    @Test("値範囲バリデーションテスト")
    func testRangeValidator() {
        let validator = ValidationEngine.range(10.0, 100.0)
        
        // 正常ケース
        #expect(validator.validate("10") == nil)
        #expect(validator.validate("50") == nil)
        #expect(validator.validate("100") == nil)
        
        // エラーケース
        #expect(validator.validate("9") == .tooSmall(minimum: 10.0))
        #expect(validator.validate("101") == .tooLarge(maximum: 100.0))
        #expect(validator.validate("abc") == .notANumber)
    }
    
    // MARK: - Date Validation Tests
    
    @Test("未来日付不可バリデーションテスト")
    func testNoFutureDateValidator() {
        let validator = ValidationEngine.noFutureDate
        
        let now = Date()
        let pastDate = now.addingTimeInterval(-3600) // 1時間前
        let futureDate = now.addingTimeInterval(3600) // 1時間後
        
        // 正常ケース（過去日付）
        #expect(validator.validate(pastDate) == nil)
        
        // エラーケース（未来日付）
        #expect(validator.validate(futureDate) == .futureDateNotAllowed)
    }
    
    @Test("過去日付不可バリデーションテスト")
    func testNoPastDateValidator() {
        let validator = ValidationEngine.noPastDate
        
        let now = Date()
        let pastDate = now.addingTimeInterval(-3600) // 1時間前
        let futureDate = now.addingTimeInterval(3600) // 1時間後
        
        // 正常ケース（未来日付）
        #expect(validator.validate(futureDate) == nil)
        
        // エラーケース（過去日付）
        #expect(validator.validate(pastDate) == .pastDateNotAllowed)
    }
    
    // MARK: - Composite Validation Tests
    
    @Test("複合バリデーションテスト")
    func testCompositeValidation() {
        let validators: [any Validator<String>] = [
            ValidationEngine.required,
            ValidationEngine.minLength(3),
            ValidationEngine.maxLength(10)
        ]
        
        // 正常ケース
        #expect(ValidationEngine.validateString("test", with: validators) == nil)
        #expect(ValidationEngine.validateString("validation", with: validators) == nil)
        
        // エラーケース（空文字）
        #expect(ValidationEngine.validateString("", with: validators) == .empty)
        
        // エラーケース（短すぎる）
        #expect(ValidationEngine.validateString("ab", with: validators) == .tooShort(minimum: 3))
        
        // エラーケース（長すぎる）
        #expect(ValidationEngine.validateString("verylongtext", with: validators) == .tooLong(maximum: 10))
    }
    
    @Test("金額バリデーション統合テスト")
    func testAmountValidation() {
        let validators: [any Validator<String>] = [
            ValidationEngine.required,
            ValidationEngine.number,
            ValidationEngine.positiveNumber,
            ValidationEngine.maxValue(1000000)
        ]
        
        // 正常ケース
        #expect(ValidationEngine.validateNumber("100", with: validators) == nil)
        #expect(ValidationEngine.validateNumber("1000", with: validators) == nil)
        
        // エラーケース
        #expect(ValidationEngine.validateNumber("", with: validators) == .empty)
        #expect(ValidationEngine.validateNumber("abc", with: validators) == .notANumber)
        #expect(ValidationEngine.validateNumber("-100", with: validators) == .notPositive)
        #expect(ValidationEngine.validateNumber("2000000", with: validators) == .tooLarge(maximum: 1000000))
    }
}