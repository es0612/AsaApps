import Foundation
import UIKit
#if FIREBASE_ENABLED
import FirebaseFirestore
import FirebaseStorage
#endif

// MARK: - Firestore Social Feed Data Service

#if FIREBASE_ENABLED
final class FirestoreSocialFeedDataService: SocialFeedDataServiceProtocol, @unchecked Sendable {
    // MARK: - Properties

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let postsCollection = "posts"

    // MARK: - Fetch Posts

    func fetchPosts() async throws -> [FirebasePost] {
        do {
            let snapshot = try await db.collection(postsCollection)
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .getDocuments()

            return snapshot.documents.compactMap { document in
                try? document.data(as: FirebasePost.self)
            }
        } catch {
            throw SocialFeedDataError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Create Post

    func createPost(
        content: String,
        authorId: String,
        authorName: String,
        authorPhotoURL: String?,
        imageData: Data?
    ) async throws -> FirebasePost {
        do {
            var imageURL: String?

            // 画像がある場合はアップロード
            if let imageData = imageData {
                imageURL = try await uploadImage(imageData)
            }

            var post = FirebasePost(
                content: content,
                authorId: authorId,
                authorName: authorName,
                authorPhotoURL: authorPhotoURL,
                imageURL: imageURL,
                likeCount: 0,
                likedByUserIds: []
            )

            let documentRef = try db.collection(postsCollection).addDocument(from: post)
            post.id = documentRef.documentID

            return post
        } catch let error as SocialFeedDataError {
            throw error
        } catch {
            throw SocialFeedDataError.createFailed(error.localizedDescription)
        }
    }

    // MARK: - Delete Post

    func deletePost(_ postId: String) async throws {
        do {
            // 画像がある場合は削除
            let document = try await db.collection(postsCollection).document(postId).getDocument()
            if let post = try? document.data(as: FirebasePost.self),
               let imageURL = post.imageURL {
                try? await deleteImage(imageURL)
            }

            try await db.collection(postsCollection).document(postId).delete()
        } catch {
            throw SocialFeedDataError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Toggle Like

    func toggleLike(on postId: String, userId: String) async throws {
        let documentRef = db.collection(postsCollection).document(postId)

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
                    // いいね解除
                    likedByUserIds.removeAll { $0 == userId }
                } else {
                    // いいね追加
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
            throw SocialFeedDataError.updateFailed(error.localizedDescription)
        }
    }

    // MARK: - Observe Posts (Real-time)

    func observePosts(_ handler: @escaping ([FirebasePost]) -> Void) -> Any {
        return db.collection(postsCollection)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error observing posts: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let posts = snapshot.documents.compactMap { document in
                    try? document.data(as: FirebasePost.self)
                }

                handler(posts)
            }
    }

    // MARK: - Remove Listener

    func removeListener(_ listener: Any) {
        if let listener = listener as? ListenerRegistration {
            listener.remove()
        }
    }

    // MARK: - Upload Image

    func uploadImage(_ data: Data) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("posts/\(fileName)")

        // 画像を圧縮
        let compressedData = compressImage(data)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            _ = try await storageRef.putDataAsync(compressedData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            throw SocialFeedDataError.uploadFailed(error.localizedDescription)
        }
    }

    // MARK: - Private Methods

    private func deleteImage(_ urlString: String) async throws {
        guard let url = URL(string: urlString) else { return }

        // Firebase StorageのURLからパスを抽出
        let path = url.path
        let storageRef = storage.reference(forURL: urlString)

        try await storageRef.delete()
    }

    private func compressImage(_ data: Data, maxSizeKB: Int = 500) -> Data {
        guard let image = UIImage(data: data) else { return data }

        var compression: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: compression) ?? data

        while compressedData.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            compressedData = image.jpegData(compressionQuality: compression) ?? data
        }

        return compressedData
    }
}

#else

// MARK: - Mock Data Service (Non-Firebase)

final class FirestoreSocialFeedDataService: SocialFeedDataServiceProtocol, @unchecked Sendable {
    private var posts: [FirebasePost] = []

    func fetchPosts() async throws -> [FirebasePost] {
        return posts.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
    }

    func createPost(content: String, authorId: String, authorName: String, authorPhotoURL: String?, imageData: Data?) async throws -> FirebasePost {
        let post = FirebasePost(
            id: UUID().uuidString,
            content: content,
            authorId: authorId,
            authorName: authorName,
            authorPhotoURL: authorPhotoURL,
            imageURL: nil,
            likeCount: 0,
            likedByUserIds: [],
            createdAt: Date()
        )
        posts.append(post)
        return post
    }

    func deletePost(_ postId: String) async throws {
        posts.removeAll { $0.id == postId }
    }

    func toggleLike(on postId: String, userId: String) async throws {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        var post = posts[index]

        if post.likedByUserIds.contains(userId) {
            post.likedByUserIds.removeAll { $0 == userId }
        } else {
            post.likedByUserIds.append(userId)
        }
        post.likeCount = post.likedByUserIds.count

        posts[index] = post
    }

    func observePosts(_ handler: @escaping ([FirebasePost]) -> Void) -> Any {
        handler(posts)
        return NSObject()
    }

    func removeListener(_ listener: Any) {
        // No-op
    }

    func uploadImage(_ data: Data) async throws -> String {
        return "mock://image/\(UUID().uuidString).jpg"
    }
}
#endif
