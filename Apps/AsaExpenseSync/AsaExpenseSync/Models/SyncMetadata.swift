import Foundation

// MARK: - SyncStatus

enum SyncStatus: String, Codable, Sendable {
    case synced = "synced"
    case syncing = "syncing"
    case pendingUpload = "pending_upload"
    case pendingDownload = "pending_download"
    case conflict = "conflict"
    case offline = "offline"
    case error = "error"

    var displayName: String {
        switch self {
        case .synced: return "同期完了"
        case .syncing: return "同期中..."
        case .pendingUpload: return "アップロード待ち"
        case .pendingDownload: return "ダウンロード待ち"
        case .conflict: return "競合あり"
        case .offline: return "オフライン"
        case .error: return "エラー"
        }
    }

    var iconName: String {
        switch self {
        case .synced: return "checkmark.circle.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .pendingUpload: return "arrow.up.circle"
        case .pendingDownload: return "arrow.down.circle"
        case .conflict: return "exclamationmark.triangle.fill"
        case .offline: return "wifi.slash"
        case .error: return "xmark.circle.fill"
        }
    }
}

// MARK: - SyncMetadata

struct SyncMetadata: Codable, Sendable {
    var lastSyncTimestamp: Date?
    var lastDeviceId: String?
    var pendingChangesCount: Int
    var conflictCount: Int
    var syncStatus: SyncStatus

    init(
        lastSyncTimestamp: Date? = nil,
        lastDeviceId: String? = nil,
        pendingChangesCount: Int = 0,
        conflictCount: Int = 0,
        syncStatus: SyncStatus = .synced
    ) {
        self.lastSyncTimestamp = lastSyncTimestamp
        self.lastDeviceId = lastDeviceId
        self.pendingChangesCount = pendingChangesCount
        self.conflictCount = conflictCount
        self.syncStatus = syncStatus
    }

    var lastSyncDescription: String {
        guard let timestamp = lastSyncTimestamp else {
            return "未同期"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - ConflictResolutionStrategy

enum ConflictResolutionStrategy: String, Codable, CaseIterable, Sendable {
    case lastWriteWins = "last_write_wins"
    case localWins = "local_wins"
    case remoteWins = "remote_wins"
    case userChoice = "user_choice"
    case merge = "merge"

    var displayName: String {
        switch self {
        case .lastWriteWins: return "最新を優先"
        case .localWins: return "このデバイスを優先"
        case .remoteWins: return "他デバイスを優先"
        case .userChoice: return "毎回選択"
        case .merge: return "自動マージ"
        }
    }

    var description: String {
        switch self {
        case .lastWriteWins: return "更新日時が新しい方を採用します"
        case .localWins: return "このデバイスの変更を常に優先します"
        case .remoteWins: return "他のデバイスの変更を常に優先します"
        case .userChoice: return "競合発生時に毎回選択します"
        case .merge: return "可能な限り両方の変更をマージします"
        }
    }
}

// MARK: - ConflictInfo

struct ConflictInfo: Sendable {
    let transactionId: String
    let localVersion: ExpenseTransaction
    let remoteVersion: ExpenseTransaction
    let conflictType: ConflictType
    let detectedAt: Date

    enum ConflictType: String, Sendable {
        case updateUpdate = "update_update"
        case updateDelete = "update_delete"
        case deleteUpdate = "delete_update"

        var displayName: String {
            switch self {
            case .updateUpdate: return "両方で更新"
            case .updateDelete: return "ローカル更新・リモート削除"
            case .deleteUpdate: return "ローカル削除・リモート更新"
            }
        }
    }

    init(
        transactionId: String,
        localVersion: ExpenseTransaction,
        remoteVersion: ExpenseTransaction,
        conflictType: ConflictType,
        detectedAt: Date = Date()
    ) {
        self.transactionId = transactionId
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.conflictType = conflictType
        self.detectedAt = detectedAt
    }
}
