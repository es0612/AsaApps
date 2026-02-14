import Foundation
import SwiftData

// MARK: - SafetyReport

/// 安全レポートモデル
@Model
public final class SafetyReport {
    public var id: UUID = UUID()
    public var title: String = ""
    public var reportDescription: String = ""
    public var alertLevelRawValue: String = SafetyAlertLevel.info.rawValue
    public var latitude: Double = 0.0
    public var longitude: Double = 0.0
    public var imageData: Data?
    public var isResolved: Bool = false
    public var reporterName: String = ""
    public var createdAt: Date = Date()
    public var resolvedAt: Date?

    public init(
        title: String,
        reportDescription: String = "",
        alertLevel: SafetyAlertLevel = .info,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        reporterName: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.reportDescription = reportDescription
        self.alertLevelRawValue = alertLevel.rawValue
        self.latitude = latitude
        self.longitude = longitude
        self.reporterName = reporterName
        self.createdAt = Date()
    }

    // MARK: - AlertLevel Accessor

    /// SafetyAlertLevel への変換アクセサ
    public var alertLevel: SafetyAlertLevel {
        get { SafetyAlertLevel(rawValue: alertLevelRawValue) ?? .info }
        set { alertLevelRawValue = newValue.rawValue }
    }

    // MARK: - Computed Properties

    /// 未解決かつ警告以上
    public var isActiveAlert: Bool {
        !isResolved && alertLevel >= .warning
    }
}
