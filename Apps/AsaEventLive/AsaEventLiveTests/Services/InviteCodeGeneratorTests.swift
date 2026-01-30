import Testing
import Foundation
@testable import AsaEventLive

// MARK: - InviteCodeGenerator Tests

struct InviteCodeGeneratorTests {
    // MARK: - Generation Tests

    @Test("招待コード生成テスト - デフォルト長")
    func testGenerateDefaultLength() {
        let code = InviteCodeGenerator.generate()
        #expect(code.count == 6)
    }

    @Test("招待コード生成テスト - カスタム長")
    func testGenerateCustomLength() {
        let code8 = InviteCodeGenerator.generate(length: 8)
        #expect(code8.count == 8)

        let code4 = InviteCodeGenerator.generate(length: 4)
        #expect(code4.count == 4)
    }

    @Test("招待コード生成テスト - ユニーク性")
    func testGenerateUniqueness() {
        var codes = Set<String>()
        for _ in 0..<100 {
            codes.insert(InviteCodeGenerator.generate())
        }
        // 100回生成してほぼ全てユニーク
        #expect(codes.count >= 95)
    }

    @Test("招待コード生成テスト - 有効文字のみ")
    func testGenerateValidCharactersOnly() {
        let validCharacters = CharacterSet(charactersIn: "ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

        for _ in 0..<50 {
            let code = InviteCodeGenerator.generate()
            let allValid = code.unicodeScalars.allSatisfy { validCharacters.contains($0) }
            #expect(allValid == true)
        }
    }

    // MARK: - Validation Tests

    @Test("招待コードバリデーション - 有効なコード")
    func testIsValidValidCode() {
        // 有効文字: ABCDEFGHJKLMNPQRSTUVWXYZ23456789（0, 1, O, Iは除外）
        #expect(InviteCodeGenerator.isValid("ABC234") == true)
        #expect(InviteCodeGenerator.isValid("ABCDEF") == true)
        #expect(InviteCodeGenerator.isValid("234567") == true)
        #expect(InviteCodeGenerator.isValid("XYZ789") == true)
    }

    @Test("招待コードバリデーション - 無効なコード（長さ）")
    func testIsValidInvalidLength() {
        #expect(InviteCodeGenerator.isValid("ABC") == false)
        #expect(InviteCodeGenerator.isValid("ABCDEFGH") == false)
        #expect(InviteCodeGenerator.isValid("") == false)
    }

    @Test("招待コードバリデーション - 無効な文字")
    func testIsValidInvalidCharacters() {
        #expect(InviteCodeGenerator.isValid("ABCD2O") == false) // O（オー）は除外
        #expect(InviteCodeGenerator.isValid("ABCD2I") == false) // I（アイ）は除外
        #expect(InviteCodeGenerator.isValid("ABCD10") == false) // 0, 1は除外
        #expect(InviteCodeGenerator.isValid("ABC1@#") == false) // 特殊文字
    }

    @Test("招待コードバリデーション - 空白含む")
    func testIsValidWithWhitespace() {
        #expect(InviteCodeGenerator.isValid(" ABC234") == true)
        #expect(InviteCodeGenerator.isValid("ABC234 ") == true)
        #expect(InviteCodeGenerator.isValid(" ABC234 ") == true)
    }

    @Test("招待コードバリデーション - 大文字小文字")
    func testIsValidCaseInsensitive() {
        #expect(InviteCodeGenerator.isValid("abc234") == true)
        #expect(InviteCodeGenerator.isValid("AbC234") == true)
    }

    // MARK: - Normalize Tests

    @Test("招待コード正規化テスト")
    func testNormalize() {
        #expect(InviteCodeGenerator.normalize("abc234") == "ABC234")
        #expect(InviteCodeGenerator.normalize(" ABC234 ") == "ABC234")
        #expect(InviteCodeGenerator.normalize("  aBc234  ") == "ABC234")
    }

    // MARK: - Format Tests

    @Test("招待コードフォーマットテスト")
    func testFormatted() {
        #expect(InviteCodeGenerator.formatted("ABC234") == "ABC-234")
        #expect(InviteCodeGenerator.formatted("XYZDEF") == "XYZ-DEF")
    }

    @Test("招待コードフォーマットテスト - 正規化付き")
    func testFormattedWithNormalization() {
        #expect(InviteCodeGenerator.formatted("abc234") == "ABC-234")
        #expect(InviteCodeGenerator.formatted(" xyzdef ") == "XYZ-DEF")
    }

    @Test("招待コードフォーマットテスト - 不正な長さ")
    func testFormattedInvalidLength() {
        #expect(InviteCodeGenerator.formatted("ABC") == "ABC")
        #expect(InviteCodeGenerator.formatted("ABCDEFGH") == "ABCDEFGH")
    }
}
