import Foundation
#if FIREBASE_ENABLED
@preconcurrency import FirebaseFirestore
#endif

// MARK: - FirestoreExpenseDataService

#if FIREBASE_ENABLED
final class FirestoreExpenseDataService: ExpenseDataServiceProtocol, @unchecked Sendable {
    // MARK: - Properties

    private let db = Firestore.firestore()

    // MARK: - Initialization

    init() {
        // Enable offline persistence
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber) // 100MB
        db.settings = settings

        print("FirestoreExpenseDataService: Initialized with offline persistence")
    }

    // MARK: - Collection References

    private func transactionsCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("transactions")
    }

    private func categoriesCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("categories")
    }

    private func budgetsCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("budgets")
    }

    // MARK: - Transactions

    func fetchTransactions(userId: String) async throws -> [ExpenseTransaction] {
        do {
            let snapshot = try await transactionsCollection(userId: userId)
                .whereField("isDeleted", isEqualTo: false)
                .order(by: "date", descending: true)
                .limit(to: 500)
                .getDocuments()

            return snapshot.documents.compactMap { doc in
                try? doc.data(as: ExpenseTransaction.self)
            }
        } catch {
            throw ExpenseDataError.fetchFailed(error.localizedDescription)
        }
    }

    func createTransaction(_ transaction: ExpenseTransaction) async throws -> ExpenseTransaction {
        var newTransaction = transaction
        newTransaction.syncVersion = 1
        newTransaction.isDeleted = false

        do {
            let docRef = try transactionsCollection(userId: transaction.userId).addDocument(from: newTransaction)
            newTransaction.id = docRef.documentID

            print("FirestoreExpenseDataService: Transaction created - \(newTransaction.title)")
            return newTransaction
        } catch {
            throw ExpenseDataError.createFailed(error.localizedDescription)
        }
    }

    func updateTransaction(_ transaction: ExpenseTransaction) async throws {
        guard let docId = transaction.id else {
            throw ExpenseDataError.updateFailed("ドキュメントIDがありません")
        }

        let docRef = transactionsCollection(userId: transaction.userId).document(docId)

        do {
            // Use transaction for optimistic locking
            try await db.runTransaction { tx, errorPointer in
                let document: DocumentSnapshot
                do {
                    document = try tx.getDocument(docRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard let remoteSyncVersion = document.data()?["syncVersion"] as? Int else {
                    return nil
                }

                // Check for conflicts
                if remoteSyncVersion > transaction.syncVersion {
                    // Conflict detected - remote version is newer
                    let remoteTransaction = try? document.data(as: ExpenseTransaction.self)
                    if let remote = remoteTransaction {
                        let conflict = ConflictInfo(
                            transactionId: docId,
                            localVersion: transaction,
                            remoteVersion: remote,
                            conflictType: .updateUpdate
                        )
                        let error = NSError(
                            domain: "ConflictError",
                            code: 409,
                            userInfo: ["conflict": conflict]
                        )
                        errorPointer?.pointee = error
                        return nil
                    }
                }

                // Update with incremented version
                var updatedTransaction = transaction
                updatedTransaction.syncVersion = remoteSyncVersion + 1

                do {
                    try tx.setData(from: updatedTransaction, forDocument: docRef)
                } catch let encodeError as NSError {
                    errorPointer?.pointee = encodeError
                    return nil
                }

                return nil
            }

            print("FirestoreExpenseDataService: Transaction updated - \(transaction.title)")
        } catch {
            throw ExpenseDataError.updateFailed(error.localizedDescription)
        }
    }

    func deleteTransaction(_ transactionId: String, userId: String) async throws {
        let docRef = transactionsCollection(userId: userId).document(transactionId)

        do {
            // Soft delete
            try await docRef.updateData([
                "isDeleted": true,
                "updatedAt": FieldValue.serverTimestamp()
            ])

            print("FirestoreExpenseDataService: Transaction deleted - \(transactionId)")
        } catch {
            throw ExpenseDataError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Categories

    func fetchCategories(userId: String) async throws -> [ExpenseCategory] {
        do {
            let snapshot = try await categoriesCollection(userId: userId)
                .order(by: "sortOrder")
                .getDocuments()

            var categories = snapshot.documents.compactMap { doc in
                try? doc.data(as: ExpenseCategory.self)
            }

            // If no categories exist, create defaults
            if categories.isEmpty {
                categories = try await initializeDefaultCategories(userId: userId)
            }

            return categories
        } catch {
            throw ExpenseDataError.fetchFailed(error.localizedDescription)
        }
    }

    func createCategory(_ category: ExpenseCategory) async throws -> ExpenseCategory {
        var newCategory = category

        do {
            let docRef = try categoriesCollection(userId: category.userId ?? "").addDocument(from: newCategory)
            newCategory.id = docRef.documentID
            return newCategory
        } catch {
            throw ExpenseDataError.createFailed(error.localizedDescription)
        }
    }

    func updateCategory(_ category: ExpenseCategory) async throws {
        guard let docId = category.id, let userId = category.userId else {
            throw ExpenseDataError.updateFailed("カテゴリIDまたはユーザーIDがありません")
        }

        do {
            try categoriesCollection(userId: userId).document(docId).setData(from: category)
        } catch {
            throw ExpenseDataError.updateFailed(error.localizedDescription)
        }
    }

    func deleteCategory(_ categoryId: String, userId: String) async throws {
        do {
            try await categoriesCollection(userId: userId).document(categoryId).delete()
        } catch {
            throw ExpenseDataError.deleteFailed(error.localizedDescription)
        }
    }

    private func initializeDefaultCategories(userId: String) async throws -> [ExpenseCategory] {
        let defaults = ExpenseCategory.allDefaultCategories.map { category -> ExpenseCategory in
            var newCategory = category
            newCategory.userId = userId
            return newCategory
        }

        let batch = db.batch()
        var createdCategories: [ExpenseCategory] = []

        for var category in defaults {
            let docRef = categoriesCollection(userId: userId).document(category.id ?? UUID().uuidString)
            category.id = docRef.documentID

            do {
                try batch.setData(from: category, forDocument: docRef)
                createdCategories.append(category)
            } catch {
                print("Error encoding category: \(error)")
            }
        }

        try await batch.commit()
        print("FirestoreExpenseDataService: Default categories initialized for user \(userId)")

        return createdCategories
    }

    // MARK: - Budgets

    func fetchBudgets(userId: String) async throws -> [Budget] {
        do {
            let snapshot = try await budgetsCollection(userId: userId)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            return snapshot.documents.compactMap { doc in
                try? doc.data(as: Budget.self)
            }
        } catch {
            throw ExpenseDataError.fetchFailed(error.localizedDescription)
        }
    }

    func createBudget(_ budget: Budget) async throws -> Budget {
        var newBudget = budget

        do {
            let docRef = try budgetsCollection(userId: budget.userId).addDocument(from: newBudget)
            newBudget.id = docRef.documentID
            return newBudget
        } catch {
            throw ExpenseDataError.createFailed(error.localizedDescription)
        }
    }

    func updateBudget(_ budget: Budget) async throws {
        guard let docId = budget.id else {
            throw ExpenseDataError.updateFailed("予算IDがありません")
        }

        do {
            try budgetsCollection(userId: budget.userId).document(docId).setData(from: budget)
        } catch {
            throw ExpenseDataError.updateFailed(error.localizedDescription)
        }
    }

    func deleteBudget(_ budgetId: String, userId: String) async throws {
        do {
            try await budgetsCollection(userId: userId).document(budgetId).delete()
        } catch {
            throw ExpenseDataError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Real-time Observation

    func observeTransactions(userId: String, handler: @escaping ([ExpenseTransaction]) -> Void) -> Any {
        return transactionsCollection(userId: userId)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "date", descending: true)
            .limit(to: 500)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("FirestoreExpenseDataService: Snapshot error - \(error.localizedDescription)")
                    return
                }

                guard let snapshot = snapshot else { return }

                let transactions = snapshot.documents.compactMap { doc in
                    try? doc.data(as: ExpenseTransaction.self)
                }

                handler(transactions)
            }
    }

    func observeCategories(userId: String, handler: @escaping ([ExpenseCategory]) -> Void) -> Any {
        return categoriesCollection(userId: userId)
            .order(by: "sortOrder")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("FirestoreExpenseDataService: Category snapshot error - \(error.localizedDescription)")
                    return
                }

                guard let snapshot = snapshot else { return }

                let categories = snapshot.documents.compactMap { doc in
                    try? doc.data(as: ExpenseCategory.self)
                }

                handler(categories)
            }
    }

    func removeListener(_ listener: Any) {
        if let listener = listener as? ListenerRegistration {
            listener.remove()
        }
    }

    // MARK: - Sync

    func getLastSyncTimestamp(userId: String) async throws -> Date? {
        let docRef = db.collection("users").document(userId)
        let document = try await docRef.getDocument()
        return document.data()?["lastSyncTimestamp"] as? Date
    }

    func updateLastSyncTimestamp(userId: String, timestamp: Date) async throws {
        try await db.collection("users").document(userId).updateData([
            "lastSyncTimestamp": timestamp
        ])
    }
}
#endif
