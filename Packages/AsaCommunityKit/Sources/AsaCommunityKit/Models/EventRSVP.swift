import Foundation
import SwiftData

// MARK: - RSVPStatus

/// 参加表明ステータス
public enum RSVPStatus: String, CaseIterable, Sendable {
    case attending = "参加"
    case maybe = "検討中"
    case declined = "不参加"

    /// SF Symbol名
    public var iconName: String {
        switch self {
        case .attending: return "checkmark.circle.fill"
        case .maybe: return "questionmark.circle"
        case .declined: return "xmark.circle"
        }
    }
}

// MARK: - EventRSVP

/// イベント参加表明モデル
@Model
public final class EventRSVP {
    public var id: UUID = UUID()
    public var statusRawValue: String = RSVPStatus.attending.rawValue
    public var message: String = ""
    public var createdAt: Date = Date()

    public var event: CommunityEvent?
    public var profile: CommunityProfile?

    public init(
        status: RSVPStatus = .attending,
        message: String = ""
    ) {
        self.id = UUID()
        self.statusRawValue = status.rawValue
        self.message = message
        self.createdAt = Date()
    }

    // MARK: - Status Accessor

    /// RSVPStatus への変換アクセサ
    public var status: RSVPStatus {
        get { RSVPStatus(rawValue: statusRawValue) ?? .attending }
        set { statusRawValue = newValue.rawValue }
    }
}
