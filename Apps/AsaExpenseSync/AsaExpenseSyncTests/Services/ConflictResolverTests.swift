import Testing
import Foundation
@testable import AsaExpenseSync

struct ConflictResolverTests {
    // MARK: - Setup

    private func createTestTransactions() -> (local: ExpenseTransaction, remote: ExpenseTransaction) {
        let local = ExpenseTransaction(
            id: "tx-1",
            amount: 1000,
            type: .expense,
            title: "ローカル更新",
            note: "ローカルメモ",
            date: Date(),
            categoryId: "food",
            userId: "user-1",
            deviceId: "device-1",
            syncVersion: 1,
            isDeleted: false,
            updatedAt: Date()
        )

        let remote = ExpenseTransaction(
            id: "tx-1",
            amount: 2000,
            type: .expense,
            title: "リモート更新",
            note: "リモートメモ",
            date: Date(),
            categoryId: "food",
            userId: "user-1",
            deviceId: "device-2",
            syncVersion: 2,
            isDeleted: false,
            updatedAt: Date().addingTimeInterval(-60) // 1分前
        )

        return (local, remote)
    }

    // MARK: - Last Write Wins Tests

    @Test("Last-Write-Wins: 最新の更新が採用される")
    func testLastWriteWinsStrategy() {
        let resolver = ConflictResolver.shared
        let (local, remote) = createTestTransactions()

        let conflict = ConflictInfo(
            transactionId: "tx-1",
            localVersion: local,
            remoteVersion: remote,
            conflictType: .updateUpdate
        )

        let resolved = resolver.resolve(conflict: conflict, strategy: .lastWriteWins)

        // Local version is newer, so it should be selected
        #expect(resolved.title == "ローカル更新")
        #expect(resolved.amount == 1000)
    }

    // MARK: - Local Wins Tests

    @Test("Local-Wins: ローカル版が常に採用される")
    func testLocalWinsStrategy() {
        let resolver = ConflictResolver.shared
        let (local, remote) = createTestTransactions()

        let conflict = ConflictInfo(
            transactionId: "tx-1",
            localVersion: local,
            remoteVersion: remote,
            conflictType: .updateUpdate
        )

        let resolved = resolver.resolve(conflict: conflict, strategy: .localWins)

        #expect(resolved.title == "ローカル更新")
        #expect(resolved.amount == 1000)
        #expect(resolved.note == "ローカルメモ")
    }

    // MARK: - Remote Wins Tests

    @Test("Remote-Wins: リモート版が常に採用される")
    func testRemoteWinsStrategy() {
        let resolver = ConflictResolver.shared
        let (local, remote) = createTestTransactions()

        let conflict = ConflictInfo(
            transactionId: "tx-1",
            localVersion: local,
            remoteVersion: remote,
            conflictType: .updateUpdate
        )

        let resolved = resolver.resolve(conflict: conflict, strategy: .remoteWins)

        #expect(resolved.title == "リモート更新")
        #expect(resolved.amount == 2000)
        #expect(resolved.note == "リモートメモ")
    }

    // MARK: - Merge Tests

    @Test("Merge: 両方の変更がマージされる")
    func testMergeStrategy() {
        let resolver = ConflictResolver.shared
        let (local, remote) = createTestTransactions()

        let conflict = ConflictInfo(
            transactionId: "tx-1",
            localVersion: local,
            remoteVersion: remote,
            conflictType: .updateUpdate
        )

        let resolved = resolver.resolve(conflict: conflict, strategy: .merge)

        // Merge should use remote for financial data, local for metadata
        #expect(resolved.amount == 2000) // Remote amount
        #expect(resolved.title == "ローカル更新") // Local title (newer)
    }

    // MARK: - Conflict Detection Tests

    @Test("競合検出: 異なるバージョンで競合が検出される")
    func testConflictDetection() {
        let resolver = ConflictResolver.shared
        let (local, remote) = createTestTransactions()

        let conflict = resolver.detectConflict(
            localTransaction: local,
            remoteTransaction: remote
        )

        #expect(conflict != nil)
        #expect(conflict?.conflictType == .updateUpdate)
    }

    @Test("競合検出: 同じバージョンでは競合なし")
    func testNoConflictSameVersion() {
        let resolver = ConflictResolver.shared

        let local = ExpenseTransaction(
            id: "tx-1",
            amount: 1000,
            type: .expense,
            title: "テスト",
            date: Date(),
            userId: "user-1",
            deviceId: "device-1",
            syncVersion: 1,
            isDeleted: false
        )

        let remote = ExpenseTransaction(
            id: "tx-1",
            amount: 1000,
            type: .expense,
            title: "テスト",
            date: Date(),
            userId: "user-1",
            deviceId: "device-2",
            syncVersion: 1,
            isDeleted: false
        )

        let conflict = resolver.detectConflict(
            localTransaction: local,
            remoteTransaction: remote
        )

        #expect(conflict == nil)
    }

    // MARK: - Delete Conflict Tests

    @Test("競合検出: ローカル削除・リモート更新の競合")
    func testDeleteUpdateConflict() {
        let resolver = ConflictResolver.shared

        let local = ExpenseTransaction(
            id: "tx-1",
            amount: 1000,
            type: .expense,
            title: "テスト",
            date: Date(),
            userId: "user-1",
            deviceId: "device-1",
            syncVersion: 2,
            isDeleted: true
        )

        let remote = ExpenseTransaction(
            id: "tx-1",
            amount: 2000,
            type: .expense,
            title: "更新済み",
            date: Date(),
            userId: "user-1",
            deviceId: "device-2",
            syncVersion: 1,
            isDeleted: false
        )

        let conflict = resolver.detectConflict(
            localTransaction: local,
            remoteTransaction: remote
        )

        #expect(conflict != nil)
        #expect(conflict?.conflictType == .deleteUpdate)
    }

    // MARK: - Batch Resolution Tests

    @Test("複数の競合を一括解決できる")
    func testBatchResolution() {
        let resolver = ConflictResolver.shared

        let conflicts: [ConflictInfo] = (1...3).map { i in
            let local = ExpenseTransaction(
                id: "tx-\(i)",
                amount: Double(i * 1000),
                type: .expense,
                title: "ローカル\(i)",
                date: Date(),
                userId: "user-1",
                deviceId: "device-1",
                syncVersion: 1,
                isDeleted: false,
                updatedAt: Date()
            )

            let remote = ExpenseTransaction(
                id: "tx-\(i)",
                amount: Double(i * 2000),
                type: .expense,
                title: "リモート\(i)",
                date: Date(),
                userId: "user-1",
                deviceId: "device-2",
                syncVersion: 2,
                isDeleted: false,
                updatedAt: Date().addingTimeInterval(-60)
            )

            return ConflictInfo(
                transactionId: "tx-\(i)",
                localVersion: local,
                remoteVersion: remote,
                conflictType: .updateUpdate
            )
        }

        let resolved = resolver.resolveMultiple(conflicts: conflicts, strategy: .localWins)

        #expect(resolved.count == 3)
        #expect(resolved.allSatisfy { $0.title.hasPrefix("ローカル") })
    }
}
