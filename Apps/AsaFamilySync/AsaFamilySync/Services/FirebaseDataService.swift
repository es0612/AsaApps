import Foundation
import FirebaseFirestore
// FirebaseFirestoreSwiftは不要（FirebaseFirestoreに統合済み）

class FirebaseDataService: FamilyDataService {
    private let db = Firestore.firestore()

    private var groupsCollection: CollectionReference {
        db.collection("groups")
    }

    private func membersCollection(groupId: String) -> CollectionReference {
        groupsCollection.document(groupId).collection("members")
    }

    private func eventsCollection(groupId: String) -> CollectionReference {
        groupsCollection.document(groupId).collection("events")
    }

    init() {
        // オフライン永続化有効化
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
    }

    // MARK: - Group Management

    func createFamilyGroup(name: String, description: String?, ownerId: String, ownerName: String, ownerEmail: String) async throws -> (group: FamilyGroup, groupId: String) {
        do {
            var group = FamilyGroup(name: name, description: description, ownerId: ownerId)
            group.createdAt = Date()
            group.updatedAt = Date()

            // グループ作成
            let docRef = try await groupsCollection.addDocument(from: group)
            group.id = docRef.documentID

            // オーナーをメンバーに追加
            let owner = FamilyMember(
                userId: ownerId,
                name: ownerName,
                email: ownerEmail,
                role: .owner
            )

            try await membersCollection(groupId: docRef.documentID).document(ownerId).setData(from: owner)

            return (group, docRef.documentID)
        } catch {
            throw mapDataError(error)
        }
    }

    func joinFamilyGroup(inviteCode: String, userId: String, userName: String, userEmail: String) async throws -> (group: FamilyGroup, groupId: String) {
        do {
            // 招待コードでグループ検索
            let querySnapshot = try await groupsCollection
                .whereField("inviteCode", isEqualTo: inviteCode.uppercased())
                .limit(to: 1)
                .getDocuments()

            guard let document = querySnapshot.documents.first else {
                throw DataServiceError.groupNotFound
            }

            guard var group = try? document.data(as: FamilyGroup.self) else {
                throw DataServiceError.groupNotFound
            }

            let groupId = document.documentID
            group.id = groupId

            // メンバー数チェック
            let membersSnapshot = try await membersCollection(groupId: groupId).getDocuments()
            if membersSnapshot.count >= group.maxMembers {
                throw DataServiceError.maxMembersReached
            }

            // 重複チェック
            if membersSnapshot.documents.contains(where: { $0.documentID == userId }) {
                throw DataServiceError.alreadyMember
            }

            // メンバー追加
            let member = FamilyMember(
                userId: userId,
                name: userName,
                email: userEmail,
                role: .member
            )

            try await membersCollection(groupId: groupId).document(userId).setData(from: member)

            return (group, groupId)
        } catch let error as DataServiceError {
            throw error
        } catch {
            throw mapDataError(error)
        }
    }

    func fetchFamilyGroup(groupId: String) async throws -> FamilyGroup {
        do {
            let document = try await groupsCollection.document(groupId).getDocument()

            guard var group = try? document.data(as: FamilyGroup.self) else {
                throw DataServiceError.groupNotFound
            }

            group.id = groupId
            return group
        } catch {
            throw mapDataError(error)
        }
    }

    func fetchFamilyMembers(groupId: String) async throws -> [FamilyMember] {
        do {
            let snapshot = try await membersCollection(groupId: groupId).getDocuments()

            return snapshot.documents.compactMap { doc in
                var member = try? doc.data(as: FamilyMember.self)
                member?.userId = doc.documentID
                return member
            }
        } catch {
            throw mapDataError(error)
        }
    }

    func removeMember(groupId: String, memberId: String) async throws {
        do {
            try await membersCollection(groupId: groupId).document(memberId).delete()
        } catch {
            throw mapDataError(error)
        }
    }

    func updateMemberRole(groupId: String, memberId: String, newRole: MemberRole) async throws {
        do {
            try await membersCollection(groupId: groupId).document(memberId).updateData([
                "role": newRole.rawValue
            ])
        } catch {
            throw mapDataError(error)
        }
    }

    func regenerateInviteCode(groupId: String) async throws -> String {
        do {
            let newCode = generateInviteCode()

            try await groupsCollection.document(groupId).updateData([
                "inviteCode": newCode,
                "updatedAt": FieldValue.serverTimestamp()
            ])

            return newCode
        } catch {
            throw mapDataError(error)
        }
    }

    func leaveFamilyGroup(groupId: String, userId: String) async throws {
        do {
            // オーナーは退出できない（先に権限委譲が必要）
            let memberDoc = try await membersCollection(groupId: groupId).document(userId).getDocument()

            guard let member = try? memberDoc.data(as: FamilyMember.self) else {
                throw DataServiceError.memberNotFound
            }

            if member.role == .owner {
                throw DataServiceError.permissionDenied
            }

            try await membersCollection(groupId: groupId).document(userId).delete()
        } catch let error as DataServiceError {
            throw error
        } catch {
            throw mapDataError(error)
        }
    }

    // MARK: - Event Management

    func createEvent(groupId: String, event: FamilyEvent) async throws -> String {
        do {
            var newEvent = event
            newEvent.createdAt = Date()
            newEvent.updatedAt = Date()

            let docRef = try await eventsCollection(groupId: groupId).addDocument(from: newEvent)
            return docRef.documentID
        } catch {
            throw mapDataError(error)
        }
    }

    func updateEvent(groupId: String, eventId: String, event: FamilyEvent) async throws {
        do {
            var updatedEvent = event
            updatedEvent.updatedAt = Date()

            try await eventsCollection(groupId: groupId).document(eventId).setData(from: updatedEvent)
        } catch {
            throw mapDataError(error)
        }
    }

    func deleteEvent(groupId: String, eventId: String) async throws {
        do {
            try await eventsCollection(groupId: groupId).document(eventId).delete()
        } catch {
            throw mapDataError(error)
        }
    }

    func fetchEvents(groupId: String) async throws -> [FamilyEvent] {
        do {
            let snapshot = try await eventsCollection(groupId: groupId)
                .order(by: "startDate", descending: false)
                .getDocuments()

            return snapshot.documents.compactMap { doc in
                var event = try? doc.data(as: FamilyEvent.self)
                event?.id = doc.documentID
                return event
            }
        } catch {
            throw mapDataError(error)
        }
    }

    func fetchEvents(groupId: String, from startDate: Date, to endDate: Date) async throws -> [FamilyEvent] {
        do {
            let snapshot = try await eventsCollection(groupId: groupId)
                .whereField("startDate", isGreaterThanOrEqualTo: Timestamp(date: startDate))
                .whereField("startDate", isLessThanOrEqualTo: Timestamp(date: endDate))
                .order(by: "startDate", descending: false)
                .getDocuments()

            return snapshot.documents.compactMap { doc in
                var event = try? doc.data(as: FamilyEvent.self)
                event?.id = doc.documentID
                return event
            }
        } catch {
            throw mapDataError(error)
        }
    }

    // MARK: - Private Helper Methods

    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    private func mapDataError(_ error: Error) -> DataServiceError {
        let nsError = error as NSError

        if nsError.domain == FirestoreErrorDomain,
           let errorCode = FirestoreErrorCode.Code(rawValue: nsError.code) {
            switch errorCode {
            case .notFound:
                return .groupNotFound
            case .permissionDenied:
                return .permissionDenied
            case .unavailable:
                return .unknown("ネットワークエラーが発生しました")
            default:
                return .unknown(error.localizedDescription)
            }
        }

        return .unknown(error.localizedDescription)
    }
}
