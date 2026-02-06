import Foundation
import SwiftData

// MARK: - ユーザー設定

/// アプリ全体の位置情報関連設定
@Model
public final class UserLocationSettings {
    @Attribute(.unique) public var id: UUID
    public var defaultRadius: Double
    public var defaultTriggerOnEntry: Bool
    public var defaultTriggerOnExit: Bool
    public var hapticFeedbackEnabled: Bool

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        defaultRadius: Double = 100,
        defaultTriggerOnEntry: Bool = true,
        defaultTriggerOnExit: Bool = false,
        hapticFeedbackEnabled: Bool = true
    ) {
        self.id = id
        self.defaultRadius = defaultRadius
        self.defaultTriggerOnEntry = defaultTriggerOnEntry
        self.defaultTriggerOnExit = defaultTriggerOnExit
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
    }

    // MARK: - デフォルト値

    public static func createDefault() -> UserLocationSettings {
        UserLocationSettings()
    }
}
