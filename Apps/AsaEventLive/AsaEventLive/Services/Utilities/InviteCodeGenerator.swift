import Foundation

// MARK: - InviteCodeGenerator

enum InviteCodeGenerator {
    // MARK: - Properties

    /// 招待コードに使用する文字（読み間違いを避けるため一部除外）
    private static let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

    /// デフォルトのコード長
    private static let defaultLength = 6

    // MARK: - Public Methods

    /// ランダムな招待コードを生成
    /// - Parameter length: コードの長さ（デフォルト: 6文字）
    /// - Returns: 生成された招待コード
    static func generate(length: Int = defaultLength) -> String {
        String((0..<length).map { _ in characters.randomElement()! })
    }

    /// 招待コードのバリデーション
    /// - Parameter code: チェックする招待コード
    /// - Returns: コードが有効な形式かどうか
    static func isValid(_ code: String) -> Bool {
        // 空白を除去して大文字化
        let normalized = code.trimmingCharacters(in: .whitespaces).uppercased()

        // 長さチェック（6文字）
        guard normalized.count == defaultLength else { return false }

        // 使用可能文字のみかチェック
        let validCharacters = CharacterSet(charactersIn: characters)
        return normalized.unicodeScalars.allSatisfy { validCharacters.contains($0) }
    }

    /// 招待コードを正規化（大文字化、空白除去）
    /// - Parameter code: 正規化する招待コード
    /// - Returns: 正規化されたコード
    static func normalize(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespaces).uppercased()
    }

    /// フォーマット付きで表示（例: ABC-123）
    /// - Parameter code: フォーマットするコード
    /// - Returns: ハイフン区切りのコード
    static func formatted(_ code: String) -> String {
        let normalized = normalize(code)
        guard normalized.count == defaultLength else { return normalized }

        let midIndex = normalized.index(normalized.startIndex, offsetBy: defaultLength / 2)
        return "\(normalized[..<midIndex])-\(normalized[midIndex...])"
    }
}
