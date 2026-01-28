import Foundation

/// 学習カテゴリを表すEnum
/// 各カテゴリは難易度の適切な時間帯と重要度スコアを持つ
enum StudyCategory: String, CaseIterable, Codable, Sendable {
    case programming = "programming"
    case language = "language"
    case certification = "certification"
    case mathematics = "mathematics"
    case science = "science"
    case business = "business"
    case creative = "creative"
    case other = "other"

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .programming: return "プログラミング"
        case .language: return "語学"
        case .certification: return "資格"
        case .mathematics: return "数学"
        case .science: return "理科"
        case .business: return "ビジネス"
        case .creative: return "クリエイティブ"
        case .other: return "その他"
        }
    }

    var icon: String {
        switch self {
        case .programming: return "laptopcomputer"
        case .language: return "globe"
        case .certification: return "doc.badge.gearshape"
        case .mathematics: return "function"
        case .science: return "atom"
        case .business: return "briefcase"
        case .creative: return "paintbrush"
        case .other: return "book"
        }
    }

    var emoji: String {
        switch self {
        case .programming: return "💻"
        case .language: return "🌍"
        case .certification: return "📜"
        case .mathematics: return "📐"
        case .science: return "🔬"
        case .business: return "💼"
        case .creative: return "🎨"
        case .other: return "📚"
        }
    }

    // MARK: - AI Optimization Properties

    /// カテゴリの基本重要度スコア（0.0-1.0）
    /// 資格や数学など集中力を要するものは高め
    var baseImportanceScore: Double {
        switch self {
        case .certification: return 0.9
        case .mathematics: return 0.85
        case .programming: return 0.8
        case .science: return 0.75
        case .language: return 0.7
        case .business: return 0.65
        case .creative: return 0.5
        case .other: return 0.4
        }
    }

    /// 朝活（5-7時）に適しているか
    /// 集中力を要するカテゴリは朝が最適
    var isMorningOptimal: Bool {
        switch self {
        case .certification, .mathematics, .programming, .science:
            return true
        case .language, .business, .creative, .other:
            return false
        }
    }

    /// 推奨セッション時間（分）
    var recommendedSessionMinutes: Int {
        switch self {
        case .certification: return 45
        case .mathematics: return 40
        case .programming: return 50
        case .science: return 40
        case .language: return 30
        case .business: return 35
        case .creative: return 60
        case .other: return 25
        }
    }
}
