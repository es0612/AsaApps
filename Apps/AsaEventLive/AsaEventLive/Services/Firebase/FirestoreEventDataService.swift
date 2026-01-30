import Foundation
#if FIREBASE_ENABLED
import FirebaseFirestore
#endif

// MARK: - Firestore Event Data Service

#if FIREBASE_ENABLED
final class FirestoreEventDataService: EventDataServiceProtocol, @unchecked Sendable {
    // MARK: - Properties

    private let db = Firestore.firestore()

    private let eventsCollection = "events"
    private let postsCollection = "posts"
    private let participantsCollection = "participants"
    private let activitiesCollection = "activities"

    // MARK: - Events

    func fetchEvents(userId: String) async throws -> [Event] {
        do {
            let snapshot = try await db.collection(eventsCollection)
                .whereField("participantIds", arrayContains: userId)
                .whereField("isDeleted", isEqualTo: false)
                .order(by: "startDate", descending: true)
                .limit(to: 50)
                .getDocuments()

            return snapshot.documents.compactMap { document in
                try? document.data(as: Event.self)
            }
        } catch {
            throw EventDataError.fetchFailed(error.localizedDescription)
        }
    }

    func fetchEvent(id: String) async throws -> Event? {
        do {
            let document = try await db.collection(eventsCollection).document(id).getDocument()
            return try? document.data(as: Event.self)
        } catch {
            throw EventDataError.fetchFailed(error.localizedDescription)
        }
    }

    func createEvent(_ event: Event) async throws -> Event {
        do {
            var newEvent = event
            newEvent.inviteCode = InviteCodeGenerator.generate()
            newEvent.createdAt = Date()
            newEvent.updatedAt = Date()

            // ホストを参加者に追加
            if !newEvent.participantIds.contains(newEvent.hostId) {
                newEvent.participantIds.append(newEvent.hostId)
            }

            let documentRef = try db.collection(eventsCollection).addDocument(from: newEvent)
            newEvent.id = documentRef.documentID

            // ホストの参加者レコードを作成
            let hostParticipant = Participant(
                eventId: newEvent.id,
                userId: newEvent.hostId,
                displayName: newEvent.hostName,
                role: .host,
                onlineStatus: .online
            )
            try db.collection(eventsCollection)
                .document(newEvent.id)
                .collection(participantsCollection)
                .addDocument(from: hostParticipant)

            // アクティビティを記録
            let activity = Activity(
                eventId: newEvent.id,
                userId: newEvent.hostId,
                userName: newEvent.hostName,
                type: .settingChanged,
                message: "イベントを作成しました"
            )
            try db.collection(eventsCollection)
                .document(newEvent.id)
                .collection(activitiesCollection)
                .addDocument(from: activity)

            return newEvent
        } catch let error as EventDataError {
            throw error
        } catch {
            throw EventDataError.createFailed(error.localizedDescription)
        }
    }

    func updateEvent(_ event: Event) async throws {
        do {
            var updatedEvent = event
            updatedEvent.updatedAt = Date()

            try db.collection(eventsCollection).document(event.id).setData(from: updatedEvent, merge: true)
        } catch {
            throw EventDataError.updateFailed(error.localizedDescription)
        }
    }

    func deleteEvent(_ eventId: String) async throws {
        do {
            try await db.collection(eventsCollection).document(eventId).updateData([
                "isDeleted": true,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            throw EventDataError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Event Join/Leave

    func joinEvent(eventId: String, inviteCode: String, participant: Participant) async throws -> Event {
        let documentRef = db.collection(eventsCollection).document(eventId)

        do {
            var resultEvent: Event?

            try await db.runTransaction { transaction, errorPointer in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(documentRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard var event = try? document.data(as: Event.self) else {
                    return nil
                }

                // 招待コードチェック
                guard InviteCodeGenerator.normalize(inviteCode) == event.inviteCode else {
                    let error = NSError(
                        domain: "EventDataError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "招待コードが無効です"]
                    )
                    errorPointer?.pointee = error
                    return nil
                }

                // 既に参加しているかチェック
                guard !event.participantIds.contains(participant.userId) else {
                    let error = NSError(
                        domain: "EventDataError",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "すでに参加しています"]
                    )
                    errorPointer?.pointee = error
                    return nil
                }

                // 参加人数上限チェック
                if let maxParticipants = event.maxParticipants,
                   event.participantIds.count >= maxParticipants {
                    let error = NSError(
                        domain: "EventDataError",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "イベントの参加人数が上限に達しています"]
                    )
                    errorPointer?.pointee = error
                    return nil
                }

                // 参加者を追加
                event.participantIds.append(participant.userId)

                transaction.updateData([
                    "participantIds": event.participantIds,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: documentRef)

                resultEvent = event
                return nil
            }

            guard let event = resultEvent else {
                throw EventDataError.joinFailed("参加処理に失敗しました")
            }

            // 参加者レコードを作成
            var newParticipant = participant
            newParticipant.eventId = eventId
            newParticipant.joinedAt = Date()
            newParticipant.onlineStatus = .online

            try db.collection(eventsCollection)
                .document(eventId)
                .collection(participantsCollection)
                .addDocument(from: newParticipant)

            // アクティビティを記録
            let activity = Activity(
                eventId: eventId,
                userId: participant.userId,
                userName: participant.displayName,
                type: .joined
            )
            try db.collection(eventsCollection)
                .document(eventId)
                .collection(activitiesCollection)
                .addDocument(from: activity)

            return event
        } catch let error as EventDataError {
            throw error
        } catch {
            throw EventDataError.joinFailed(error.localizedDescription)
        }
    }

    func leaveEvent(eventId: String, userId: String) async throws {
        let documentRef = db.collection(eventsCollection).document(eventId)

        do {
            var leavingParticipantName: String?

            try await db.runTransaction { transaction, errorPointer in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(documentRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard var event = try? document.data(as: Event.self) else {
                    return nil
                }

                // ホストは退出不可
                guard event.hostId != userId else {
                    let error = NSError(
                        domain: "EventDataError",
                        code: -4,
                        userInfo: [NSLocalizedDescriptionKey: "ホストは退出できません"]
                    )
                    errorPointer?.pointee = error
                    return nil
                }

                // 参加者から削除
                event.participantIds.removeAll { $0 == userId }
                event.coHostIds.removeAll { $0 == userId }

                transaction.updateData([
                    "participantIds": event.participantIds,
                    "coHostIds": event.coHostIds,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: documentRef)

                return nil
            }

            // 参加者レコードを削除
            let participantsSnapshot = try await db.collection(eventsCollection)
                .document(eventId)
                .collection(participantsCollection)
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            for document in participantsSnapshot.documents {
                if let participant = try? document.data(as: Participant.self) {
                    leavingParticipantName = participant.displayName
                }
                try await document.reference.delete()
            }

            // アクティビティを記録
            if let name = leavingParticipantName {
                let activity = Activity(
                    eventId: eventId,
                    userId: userId,
                    userName: name,
                    type: .left
                )
                try db.collection(eventsCollection)
                    .document(eventId)
                    .collection(activitiesCollection)
                    .addDocument(from: activity)
            }
        } catch let error as EventDataError {
            throw error
        } catch {
            throw EventDataError.leaveFailed(error.localizedDescription)
        }
    }

    // MARK: - Posts

    func fetchPosts(eventId: String) async throws -> [EventPost] {
        do {
            let snapshot = try await db.collection(eventsCollection)
                .document(eventId)
                .collection(postsCollection)
                .whereField("isDeleted", isEqualTo: false)
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()

            return snapshot.documents.compactMap { document in
                try? document.data(as: EventPost.self)
            }
        } catch {
            throw EventDataError.fetchFailed(error.localizedDescription)
        }
    }

    func createPost(_ post: EventPost) async throws -> EventPost {
        do {
            var newPost = post
            newPost.createdAt = Date()
            newPost.updatedAt = Date()

            let documentRef = try db.collection(eventsCollection)
                .document(post.eventId)
                .collection(postsCollection)
                .addDocument(from: newPost)

            newPost.id = documentRef.documentID

            // アクティビティを記録
            let activity = Activity(
                eventId: post.eventId,
                userId: post.authorId,
                userName: post.authorName,
                type: post.type == .milestone ? .milestone : .posted,
                message: post.type == .milestone ? post.content : "",
                relatedObjectId: newPost.id
            )
            try db.collection(eventsCollection)
                .document(post.eventId)
                .collection(activitiesCollection)
                .addDocument(from: activity)

            return newPost
        } catch {
            throw EventDataError.createFailed(error.localizedDescription)
        }
    }

    func updatePost(_ post: EventPost) async throws {
        do {
            var updatedPost = post
            updatedPost.updatedAt = Date()

            try db.collection(eventsCollection)
                .document(post.eventId)
                .collection(postsCollection)
                .document(post.id)
                .setData(from: updatedPost, merge: true)
        } catch {
            throw EventDataError.updateFailed(error.localizedDescription)
        }
    }

    func deletePost(_ postId: String, eventId: String) async throws {
        do {
            try await db.collection(eventsCollection)
                .document(eventId)
                .collection(postsCollection)
                .document(postId)
                .updateData([
                    "isDeleted": true,
                    "updatedAt": FieldValue.serverTimestamp()
                ])
        } catch {
            throw EventDataError.deleteFailed(error.localizedDescription)
        }
    }

    func toggleLike(postId: String, eventId: String, userId: String) async throws {
        let documentRef = db.collection(eventsCollection)
            .document(eventId)
            .collection(postsCollection)
            .document(postId)

        do {
            try await db.runTransaction { transaction, errorPointer in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(documentRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard var likedByUserIds = document.data()?["likedByUserIds"] as? [String] else {
                    return nil
                }

                if likedByUserIds.contains(userId) {
                    likedByUserIds.removeAll { $0 == userId }
                } else {
                    likedByUserIds.append(userId)
                }

                transaction.updateData([
                    "likedByUserIds": likedByUserIds,
                    "likeCount": likedByUserIds.count,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: documentRef)

                return nil
            }
        } catch {
            throw EventDataError.updateFailed(error.localizedDescription)
        }
    }

    // MARK: - Participants

    func fetchParticipants(eventId: String) async throws -> [Participant] {
        do {
            let snapshot = try await db.collection(eventsCollection)
                .document(eventId)
                .collection(participantsCollection)
                .order(by: "role")
                .getDocuments()

            return snapshot.documents.compactMap { document in
                try? document.data(as: Participant.self)
            }
        } catch {
            throw EventDataError.fetchFailed(error.localizedDescription)
        }
    }

    func updateParticipant(_ participant: Participant) async throws {
        do {
            // 参加者ドキュメントを検索
            let snapshot = try await db.collection(eventsCollection)
                .document(participant.eventId)
                .collection(participantsCollection)
                .whereField("userId", isEqualTo: participant.userId)
                .getDocuments()

            guard let document = snapshot.documents.first else {
                throw EventDataError.notFound
            }

            try document.reference.setData(from: participant, merge: true)
        } catch let error as EventDataError {
            throw error
        } catch {
            throw EventDataError.updateFailed(error.localizedDescription)
        }
    }

    func updateOnlineStatus(eventId: String, userId: String, status: OnlineStatus) async throws {
        do {
            let snapshot = try await db.collection(eventsCollection)
                .document(eventId)
                .collection(participantsCollection)
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            guard let document = snapshot.documents.first else {
                throw EventDataError.notFound
            }

            try await document.reference.updateData([
                "onlineStatus": status.rawValue,
                "lastSeenAt": FieldValue.serverTimestamp()
            ])
        } catch let error as EventDataError {
            throw error
        } catch {
            throw EventDataError.updateFailed(error.localizedDescription)
        }
    }

    // MARK: - Activities

    func fetchActivities(eventId: String, limit: Int = 50) async throws -> [Activity] {
        do {
            let snapshot = try await db.collection(eventsCollection)
                .document(eventId)
                .collection(activitiesCollection)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .getDocuments()

            return snapshot.documents.compactMap { document in
                try? document.data(as: Activity.self)
            }
        } catch {
            throw EventDataError.fetchFailed(error.localizedDescription)
        }
    }

    func createActivity(_ activity: Activity) async throws -> Activity {
        do {
            var newActivity = activity
            newActivity.createdAt = Date()

            let documentRef = try db.collection(eventsCollection)
                .document(activity.eventId)
                .collection(activitiesCollection)
                .addDocument(from: newActivity)

            newActivity.id = documentRef.documentID
            return newActivity
        } catch {
            throw EventDataError.createFailed(error.localizedDescription)
        }
    }

    // MARK: - Real-time Observation

    func observeEvents(userId: String, handler: @escaping ([Event]) -> Void) -> Any {
        return db.collection(eventsCollection)
            .whereField("participantIds", arrayContains: userId)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "startDate", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error observing events: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let events = snapshot.documents.compactMap { document in
                    try? document.data(as: Event.self)
                }
                handler(events)
            }
    }

    func observeEvent(eventId: String, handler: @escaping (Event?) -> Void) -> Any {
        return db.collection(eventsCollection)
            .document(eventId)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error observing event: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let event = try? snapshot.data(as: Event.self)
                handler(event)
            }
    }

    func observePosts(eventId: String, handler: @escaping ([EventPost]) -> Void) -> Any {
        return db.collection(eventsCollection)
            .document(eventId)
            .collection(postsCollection)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error observing posts: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let posts = snapshot.documents.compactMap { document in
                    try? document.data(as: EventPost.self)
                }
                handler(posts)
            }
    }

    func observeParticipants(eventId: String, handler: @escaping ([Participant]) -> Void) -> Any {
        return db.collection(eventsCollection)
            .document(eventId)
            .collection(participantsCollection)
            .order(by: "role")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error observing participants: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let participants = snapshot.documents.compactMap { document in
                    try? document.data(as: Participant.self)
                }
                handler(participants)
            }
    }

    func observeActivities(eventId: String, limit: Int = 50, handler: @escaping ([Activity]) -> Void) -> Any {
        return db.collection(eventsCollection)
            .document(eventId)
            .collection(activitiesCollection)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error observing activities: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let activities = snapshot.documents.compactMap { document in
                    try? document.data(as: Activity.self)
                }
                handler(activities)
            }
    }

    func removeListener(_ listener: Any) {
        if let listener = listener as? ListenerRegistration {
            listener.remove()
        }
    }
}

#else

// MARK: - Non-Firebase Fallback

final class FirestoreEventDataService: EventDataServiceProtocol, @unchecked Sendable {
    private let mockService = MockEventDataService()

    func fetchEvents(userId: String) async throws -> [Event] {
        try await mockService.fetchEvents(userId: userId)
    }

    func fetchEvent(id: String) async throws -> Event? {
        try await mockService.fetchEvent(id: id)
    }

    func createEvent(_ event: Event) async throws -> Event {
        try await mockService.createEvent(event)
    }

    func updateEvent(_ event: Event) async throws {
        try await mockService.updateEvent(event)
    }

    func deleteEvent(_ eventId: String) async throws {
        try await mockService.deleteEvent(eventId)
    }

    func joinEvent(eventId: String, inviteCode: String, participant: Participant) async throws -> Event {
        try await mockService.joinEvent(eventId: eventId, inviteCode: inviteCode, participant: participant)
    }

    func leaveEvent(eventId: String, userId: String) async throws {
        try await mockService.leaveEvent(eventId: eventId, userId: userId)
    }

    func fetchPosts(eventId: String) async throws -> [EventPost] {
        try await mockService.fetchPosts(eventId: eventId)
    }

    func createPost(_ post: EventPost) async throws -> EventPost {
        try await mockService.createPost(post)
    }

    func updatePost(_ post: EventPost) async throws {
        try await mockService.updatePost(post)
    }

    func deletePost(_ postId: String, eventId: String) async throws {
        try await mockService.deletePost(postId, eventId: eventId)
    }

    func toggleLike(postId: String, eventId: String, userId: String) async throws {
        try await mockService.toggleLike(postId: postId, eventId: eventId, userId: userId)
    }

    func fetchParticipants(eventId: String) async throws -> [Participant] {
        try await mockService.fetchParticipants(eventId: eventId)
    }

    func updateParticipant(_ participant: Participant) async throws {
        try await mockService.updateParticipant(participant)
    }

    func updateOnlineStatus(eventId: String, userId: String, status: OnlineStatus) async throws {
        try await mockService.updateOnlineStatus(eventId: eventId, userId: userId, status: status)
    }

    func fetchActivities(eventId: String, limit: Int) async throws -> [Activity] {
        try await mockService.fetchActivities(eventId: eventId, limit: limit)
    }

    func createActivity(_ activity: Activity) async throws -> Activity {
        try await mockService.createActivity(activity)
    }

    func observeEvents(userId: String, handler: @escaping ([Event]) -> Void) -> Any {
        mockService.observeEvents(userId: userId, handler: handler)
    }

    func observeEvent(eventId: String, handler: @escaping (Event?) -> Void) -> Any {
        mockService.observeEvent(eventId: eventId, handler: handler)
    }

    func observePosts(eventId: String, handler: @escaping ([EventPost]) -> Void) -> Any {
        mockService.observePosts(eventId: eventId, handler: handler)
    }

    func observeParticipants(eventId: String, handler: @escaping ([Participant]) -> Void) -> Any {
        mockService.observeParticipants(eventId: eventId, handler: handler)
    }

    func observeActivities(eventId: String, limit: Int, handler: @escaping ([Activity]) -> Void) -> Any {
        mockService.observeActivities(eventId: eventId, limit: limit, handler: handler)
    }

    func removeListener(_ listener: Any) {
        mockService.removeListener(listener)
    }
}
#endif
