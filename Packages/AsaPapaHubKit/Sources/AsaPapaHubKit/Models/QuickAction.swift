import Foundation
import SwiftData

// MARK: - クイックアクション

@Model
public final class QuickAction {
    public var id: UUID
    public var title: String
    public var iconName: String
    public var domainRawValue: String
    public var actionTypeRawValue: String
    public var isEnabled: Bool
    public var order: Int

    public init(
        id: UUID = UUID(),
        title: String = "",
        iconName: String = "star",
        domainRawValue: String = LifeDomain.morning.rawValue,
        actionTypeRawValue: String = "navigate",
        isEnabled: Bool = true,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.domainRawValue = domainRawValue
        self.actionTypeRawValue = actionTypeRawValue
        self.isEnabled = isEnabled
        self.order = order
    }

    // MARK: - Computed Properties

    public var domain: LifeDomain {
        get { LifeDomain(rawValue: domainRawValue) ?? .morning }
        set { domainRawValue = newValue.rawValue }
    }
}
