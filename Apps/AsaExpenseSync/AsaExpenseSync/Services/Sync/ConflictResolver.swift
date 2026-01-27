import Foundation

// MARK: - ConflictResolver

final class ConflictResolver: Sendable {
    // MARK: - Singleton

    static let shared = ConflictResolver()

    private init() {}

    // MARK: - Resolution

    func resolve(
        conflict: ConflictInfo,
        strategy: ConflictResolutionStrategy
    ) -> ExpenseTransaction {
        switch strategy {
        case .lastWriteWins:
            return resolveByLastWrite(conflict: conflict)

        case .localWins:
            return conflict.localVersion

        case .remoteWins:
            return conflict.remoteVersion

        case .merge:
            return mergeTransactions(conflict: conflict)

        case .userChoice:
            // Return local version by default; UI should handle user selection
            return conflict.localVersion
        }
    }

    // MARK: - Resolution Strategies

    private func resolveByLastWrite(conflict: ConflictInfo) -> ExpenseTransaction {
        let localTime = conflict.localVersion.updatedAt ?? conflict.localVersion.localModifiedAt ?? Date.distantPast
        let remoteTime = conflict.remoteVersion.updatedAt ?? Date.distantPast

        if localTime > remoteTime {
            print("ConflictResolver: Resolved by lastWriteWins - local version selected")
            return conflict.localVersion
        } else {
            print("ConflictResolver: Resolved by lastWriteWins - remote version selected")
            return conflict.remoteVersion
        }
    }

    private func mergeTransactions(conflict: ConflictInfo) -> ExpenseTransaction {
        // Merge strategy: Use remote for financial data, local for metadata
        var merged = conflict.remoteVersion

        // Keep local title and note if they were modified more recently
        let localTime = conflict.localVersion.localModifiedAt ?? Date.distantPast
        let remoteTime = conflict.remoteVersion.updatedAt ?? Date.distantPast

        if localTime > remoteTime {
            merged.title = conflict.localVersion.title
            merged.note = conflict.localVersion.note
        }

        // Always use the higher sync version + 1
        merged.syncVersion = max(conflict.localVersion.syncVersion, conflict.remoteVersion.syncVersion) + 1

        print("ConflictResolver: Resolved by merge - combined version created")
        return merged
    }

    // MARK: - Conflict Detection

    func detectConflict(
        localTransaction: ExpenseTransaction,
        remoteTransaction: ExpenseTransaction
    ) -> ConflictInfo? {
        // Check if both have changes (different sync versions but same base)
        guard localTransaction.syncVersion != remoteTransaction.syncVersion else {
            return nil
        }

        // Determine conflict type
        let conflictType: ConflictInfo.ConflictType

        if localTransaction.isDeleted && !remoteTransaction.isDeleted {
            conflictType = .deleteUpdate
        } else if !localTransaction.isDeleted && remoteTransaction.isDeleted {
            conflictType = .updateDelete
        } else {
            conflictType = .updateUpdate
        }

        return ConflictInfo(
            transactionId: localTransaction.transactionId,
            localVersion: localTransaction,
            remoteVersion: remoteTransaction,
            conflictType: conflictType
        )
    }

    // MARK: - Batch Resolution

    func resolveMultiple(
        conflicts: [ConflictInfo],
        strategy: ConflictResolutionStrategy
    ) -> [ExpenseTransaction] {
        return conflicts.map { resolve(conflict: $0, strategy: strategy) }
    }
}

// MARK: - SyncEngine

final class SyncEngine: @unchecked Sendable {
    // MARK: - Properties

    private let dataService: ExpenseDataServiceProtocol
    private let conflictResolver: ConflictResolver

    var conflictResolutionStrategy: ConflictResolutionStrategy = .lastWriteWins
    var pendingConflicts: [ConflictInfo] = []

    // MARK: - Initialization

    init(
        dataService: ExpenseDataServiceProtocol,
        conflictResolver: ConflictResolver = .shared
    ) {
        self.dataService = dataService
        self.conflictResolver = conflictResolver
    }

    // MARK: - Sync Operations

    func syncTransactions(
        localTransactions: [ExpenseTransaction],
        remoteTransactions: [ExpenseTransaction],
        userId: String
    ) async throws -> SyncResult {
        var toUpload: [ExpenseTransaction] = []
        var toDownload: [ExpenseTransaction] = []
        var conflicts: [ConflictInfo] = []

        let localById = Dictionary(uniqueKeysWithValues: localTransactions.compactMap { tx -> (String, ExpenseTransaction)? in
            guard let id = tx.id else { return nil }
            return (id, tx)
        })

        let remoteById = Dictionary(uniqueKeysWithValues: remoteTransactions.compactMap { tx -> (String, ExpenseTransaction)? in
            guard let id = tx.id else { return nil }
            return (id, tx)
        })

        // Check for local-only transactions (need upload)
        for (id, localTx) in localById {
            if remoteById[id] == nil {
                toUpload.append(localTx)
            }
        }

        // Check for remote-only transactions (need download)
        for (id, remoteTx) in remoteById {
            if localById[id] == nil {
                toDownload.append(remoteTx)
            }
        }

        // Check for conflicts (both have changes)
        for (id, localTx) in localById {
            if let remoteTx = remoteById[id] {
                if let conflict = conflictResolver.detectConflict(
                    localTransaction: localTx,
                    remoteTransaction: remoteTx
                ) {
                    conflicts.append(conflict)
                }
            }
        }

        // Resolve conflicts
        var resolved: [ExpenseTransaction] = []
        for conflict in conflicts {
            let resolvedTx = conflictResolver.resolve(
                conflict: conflict,
                strategy: conflictResolutionStrategy
            )
            resolved.append(resolvedTx)
        }

        // Store unresolved conflicts for user review (if strategy is userChoice)
        if conflictResolutionStrategy == .userChoice {
            pendingConflicts = conflicts
        }

        return SyncResult(
            uploaded: toUpload.count,
            downloaded: toDownload.count,
            conflictsResolved: resolved.count,
            pendingConflicts: pendingConflicts.count
        )
    }

    // MARK: - Conflict Resolution

    func resolveConflict(
        _ conflict: ConflictInfo,
        with selectedVersion: ExpenseTransaction
    ) async throws {
        try await dataService.updateTransaction(selectedVersion)
        pendingConflicts.removeAll { $0.transactionId == conflict.transactionId }
    }

    func resolveAllConflicts(strategy: ConflictResolutionStrategy) async throws {
        for conflict in pendingConflicts {
            let resolved = conflictResolver.resolve(conflict: conflict, strategy: strategy)
            try await dataService.updateTransaction(resolved)
        }
        pendingConflicts.removeAll()
    }
}

// MARK: - SyncResult

struct SyncResult: Sendable {
    let uploaded: Int
    let downloaded: Int
    let conflictsResolved: Int
    let pendingConflicts: Int

    var summary: String {
        "アップロード: \(uploaded)件, ダウンロード: \(downloaded)件, 競合解決: \(conflictsResolved)件"
    }

    var hasPendingConflicts: Bool {
        pendingConflicts > 0
    }
}
