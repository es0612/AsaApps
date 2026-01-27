import Foundation
import SwiftData

// MARK: - LocalTransaction

@Model
final class LocalTransaction {
    @Attribute(.unique) var id: UUID
    var remoteId: String?
    var amount: Double
    var typeRawValue: String
    var title: String
    var note: String?
    var date: Date
    var categoryId: String?
    var createdAt: Date
    var updatedAt: Date

    // Sync State
    var syncStatusRawValue: String
    var localVersion: Int
    var remoteVersion: Int?
    var needsUpload: Bool
    var needsDownload: Bool
    var userId: String
    var deviceId: String

    // MARK: - Computed Properties

    var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRawValue) ?? .synced }
        set { syncStatusRawValue = newValue.rawValue }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        remoteId: String? = nil,
        amount: Double,
        type: TransactionType,
        title: String,
        note: String? = nil,
        date: Date = Date(),
        categoryId: String? = nil,
        userId: String,
        deviceId: String,
        syncStatus: SyncStatus = .pendingUpload,
        localVersion: Int = 1,
        remoteVersion: Int? = nil
    ) {
        self.id = id
        self.remoteId = remoteId
        self.amount = amount
        self.typeRawValue = type.rawValue
        self.title = title
        self.note = note
        self.date = date
        self.categoryId = categoryId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatusRawValue = syncStatus.rawValue
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.needsUpload = syncStatus == .pendingUpload
        self.needsDownload = syncStatus == .pendingDownload
        self.userId = userId
        self.deviceId = deviceId
    }

    // MARK: - Conversion

    func toExpenseTransaction() -> ExpenseTransaction {
        ExpenseTransaction(
            id: remoteId,
            amount: amount,
            type: type,
            title: title,
            note: note,
            date: date,
            categoryId: categoryId,
            userId: userId,
            deviceId: deviceId,
            syncVersion: localVersion,
            isDeleted: false,
            createdAt: createdAt,
            updatedAt: updatedAt,
            localModifiedAt: updatedAt
        )
    }

    static func fromExpenseTransaction(_ transaction: ExpenseTransaction, deviceId: String) -> LocalTransaction {
        LocalTransaction(
            remoteId: transaction.id,
            amount: transaction.amount,
            type: transaction.type,
            title: transaction.title,
            note: transaction.note,
            date: transaction.date,
            categoryId: transaction.categoryId,
            userId: transaction.userId,
            deviceId: deviceId,
            syncStatus: .synced,
            localVersion: transaction.syncVersion,
            remoteVersion: transaction.syncVersion
        )
    }
}

// MARK: - LocalCategory

@Model
final class LocalCategory {
    @Attribute(.unique) var id: UUID
    var remoteId: String?
    var name: String
    var iconName: String
    var colorHex: String
    var transactionTypeRawValue: String
    var isDefault: Bool
    var sortOrder: Int
    var userId: String?

    // MARK: - Computed Properties

    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRawValue) ?? .expense }
        set { transactionTypeRawValue = newValue.rawValue }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        remoteId: String? = nil,
        name: String,
        iconName: String,
        colorHex: String,
        transactionType: TransactionType,
        isDefault: Bool = false,
        sortOrder: Int = 0,
        userId: String? = nil
    ) {
        self.id = id
        self.remoteId = remoteId
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.transactionTypeRawValue = transactionType.rawValue
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.userId = userId
    }

    // MARK: - Conversion

    func toExpenseCategory() -> ExpenseCategory {
        ExpenseCategory(
            id: remoteId,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            transactionType: transactionType,
            isDefault: isDefault,
            sortOrder: sortOrder,
            userId: userId
        )
    }

    static func fromExpenseCategory(_ category: ExpenseCategory) -> LocalCategory {
        LocalCategory(
            remoteId: category.id,
            name: category.name,
            iconName: category.iconName,
            colorHex: category.colorHex,
            transactionType: category.transactionType,
            isDefault: category.isDefault,
            sortOrder: category.sortOrder,
            userId: category.userId
        )
    }
}
